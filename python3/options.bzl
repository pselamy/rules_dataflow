native.genrule(
    name="generate_{}".format(metadata_script_name),
    srcs=srcs,
    outs=["{}.py".format(metadata_script_name)],
    cmd=r"""
cat > $@ << 'EOF'
import sys
import json
import apache_beam

src_file = '$(execpath $<)'
main_class = '{main_class}'

with open(src_file) as f:
    script_code = f.read()

script_globals = globals().copy()
script_locals = locals().copy()

exec(script_code, script_globals, script_locals)

options = script_locals.get(main_class)()
metadata = []

for name, value in options.__class__.__dict__.items():
    if isinstance(value, property) and issubclass(value.fget.__class__, apache_beam.options.value_provider.ValueProvider):
        option = {{
            'name': name,
            'label': name,
            'helpText': value.__doc__,
            'is_optional': True
        }}
        metadata.append(option)

metadata_json = {{
    'name': '{metadata_name}',
    'description': 'Dataflow Flex Template for {
