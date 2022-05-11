# PSDK Plugin Manager

The PSDK Plugin Manager allow scripter & makers to distribute plugins that adds things to PSDK. The PSDK Plugin Manager also allow the plugins to perform checks in order to ensure the plugin is both compatible with the current version of PSDK & all the other plugins that were not in the dependency list.

## Principles

Here's the principles of PSDK Plugin Manager:
1. A plugin is a single archive file stored in `project_root/scripts`   
    eg. `project_root/scripts/ebdx.psdkplug`
2. A plugin can store its configuration into `project_root/Data/configs/plugins`   
    This gives the user flexibility and let them configure the plugin the way they want to use it.
3. Plugins are ordered by dependency when the PSDK Plugin Manager install them.
4. Plugins cannot have cyclic dependency (a depends on b, b depends on c which depends on a).
5. When a plugin depends on a plugin that is not there, it will be downloaded by the PSDK Plugin Manager
6. Plugins can execute a test script to test if PSDK provide what they need.
7. Plugins can execute a test script to test if other plugins are not interfeering with them.
8. Plugins can install graphics, audio and Data files.
9. User can keep files installed by plugin if they desires to.
10. `project_root/scripts/00000 Plugins` is always cleared when plugins gets installed/removed.

## When the PSDK Plugin Manager kicks in?

The PSDK Plugin Manager install/remove plugins when one of the following criteria is met:
- A `.psdkplug` file was added or removed.
- The PSDK version changed (update)
- The command `game --util=plugin load` was called.

## How to build a plugin?

In order to build a plugin you will have to create a folder holding the name of your plugin in `project_root/scripts`. This plugin folder should contain at least the following file `config.yml`.

### The `config.yml` file

This file looks like this:
```yml
--- !ruby/object:PluginManager::Config
name: test
authors:
- Yuri
version: 0.0.0.0
deps: []
psdk_compatibility_script: psdk.rb
retry_psdk_compatibility_after_plugin_load: false
additional_compatibility_script: add.rb
added_files:
- Data/configs/plugins/test/*.yml
```

Here's the description of each field of the `config.yml` file:
- `name`: String containing the name of the plugin. It should be a valid filename.
- `authors`: List of authors who were involved in the plugin.
- `version`: Current version of the plugin, should use the format `m.b.a.c` where m is major, b is beta, a is alpha and c is correction. All should be numbers.
- `deps`: List of dependencies (explained below).
- `psdk_compatibility_script`: Name of the script to execute to check if the plugin is compatible with PSDK. This field is optional, you can remove this line if you don't use it.
- `retry_psdk_compatibility_after_plugin_load`: Boolean telling if the `psdk_compatibility_script` should also be executed after all the plugins were installed and loaded.
- `additional_compatibility_script`: Name of the script to execute to check if the other plugins works fine with this plugin. This field is optional, you can remove this line if you don't use it.
- `added_files`: List of the files the plugin adds, this is actually parameter sent to `Dir[]` but you can specify each files one by one. The files needs to exist at their definitive location when you build the plugin if you want them to be added in the plugin.

### The `deps` in the `config.yml` file

The `deps` contains a description of the dependency the plugin needs to work. It also tells which plugin is incompatible. You can specify a minimum and maximum version (inclusive) but that's optional. 

In order to ensure the dependency can be downloaded, a url should specify and it should let PSDK download the plugin file without any "download wall" (eg. mediafire, mega requires a browser to download the file and it makes PSDK unable to download the file).

Here's all the field of the entries in `deps`:
- `:name`: Name of the dependence plugin (or incompatible plugin)
- `:incompatible`: Boolean telling if the plugin in `:name` is incompatible or is a dependence.
- `:url`: URL of the plugin if it's a dependence.
- `:version_min`: String giving minimum version of the dependency (optional, inclusive)
- `:version_max`: String giving maximum version of the dependency (optional, inclusive)

Example of `deps` description:
- depends on `super_plugin`
- depends on `ruby_descr` with minimum version `3.0.1.0`
- depends on `yaml` with maximum version `1.5.3.0`
- depends on `litergss` between version `2.0.0.0` and `2.255.255.255`
- is incompatible with `rgss`
- is incompatible with `essentials` between version `1.0.0.0` and `25.0.0.0`

```yaml
deps:
- :name: super_plugin
  :url: https://download.psdk.pokemonworkshop.com/plugins/super_plugin.psdkplug
- :name: ruby_descr
  :url: https://download.psdk.pokemonworkshop.com/plugins/ruby_descr.psdkplug
  :version_min: 3.0.1.0
- :name: yaml
  :url: https://download.psdk.pokemonworkshop.com/plugins/yaml.psdkplug
  :version_max: 1.5.3.0
- :name: litergss
  :url: https://download.psdk.pokemonworkshop.com/plugins/litergss.psdkplug
  :version_min: 2.0.0.0
  :version_max: 2.255.255.255
- :name: rgss
  :incompatible: true
- :name: essentials
  :incompatible: true
  :version_min: 1.0.0.0
  :version_max: 25.0.0.0
```

### The command to run to build the plugin

Once you've made sure everything has been setup you can run the command:
```
game --util=plugin build name
```
Replace `name` with the name of the plugin. You can build several plugin at once by adding names after the name of the first plugin to build.

You should end up with a `.psdkplug` file with the name you provided in `config.yml` in the `project_root/scripts` folder.

### How to check if all the files were properly added in the plugin

The easiest way to know if the files were all added is to run the command:
```
game --util=plugin load
```

This will force the plugin to reinstall, and then it'll show all the files that could not be extracted because they already exist (since the plugin was already installed / the files were expected to be at their final destination).

Here's an example of output with a plugin called `test` extracting 3 files:
```
================================================================================
#                           PSDK Plugin Manager v1.0                           #
# Something changed in your plugins!                                           #
================================================================================
PSDK checked!
Extracting scripts for test plugin...
Extracting resources of test plugin...
Skipping Data/configs/credits_config.yml (exist)
Skipping Data/configs/save_config.yml (exist)
Skipping Data/configs/scene_title_config.yml (exist)
```

## How to distribute a plugin

The most important thing when you distribute a plugin is to know if your plugin might be a dependency of other plugins or not. If it is, you have to upload the plugin file to a FTP (or ask Pokémon Workshop if they can host your plugin file). The uploaded file should be accessible from `HTTPS` protocol and clicking on the link should immediately download the file without any redirect or any other pages.

Once done you can tell the user to download the file into `project_root/scripts`. This should be enought to have the plugin to work, if you described the dependency properly it should be handled properly.

Note: If there's any incompatibilities with other plugins or some PSDK version, please inform the user before they download the file!
