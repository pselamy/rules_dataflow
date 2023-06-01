# Minimal Example
dataflow_flex_py3_image(
    name = "profile_pipeline",
    app_version = "0.0.1",
    base = "@dataflow_python310_template_launcher_base//image",
    packages = [
        "common",
    ],
    requires = [
        "Faker==18.9.0",
        "apache-beam[gcp]==2.47.0",
    ],
    layers = [
      "//common:profile_generator",  
      "//common:profile_processor",  
    ],
)
