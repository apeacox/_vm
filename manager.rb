if File.exists? (shell_proxy_path = File.expand_path("../shell-proxy/lib", __FILE__))
  $:.unshift shell_proxy_path
end
require 'shell-proxy'

UNDERSCORE_VM_VERSION = "0.0.0"

module Plugin
  def self.uuid
    @current_id ||= 0
    @current_id += 1
    :"unique_plugin_method_#{@current_id}"
  end
end

Dir[File.expand_path("../plugin/*.rb", __FILE__)].each do |f|
  require f
end

class Manager < ShellProxy
  @@plugins = Hash.new { |h, k| h[k] = Array.new }

  def self.add_hook(to, &block)
    uuid = Plugin.uuid
    @@plugins[to] << uuid
    define_method(uuid, &block)
  end

  attr_reader :name
  def initialize(name)
    @name = name
  end

  def build(io = nil)
  __main__(io) do
    def for_all(name, iter, &block)
      __for(bare("${__#{name}_LIST}"), iter, &block)
    end
    build_main
  end
  end

  def build_main
    __function("_#{name}") do
      __case(raw("$1")) do |c|
        c.when("-h|--help") do
          echo raw("usage: _#{name} [version] [opts]")
        end
        c.when("-v|--version") do
          echo raw("_#{name} version #{UNDERSCORE_VM_VERSION}")
        end
        c.when("system") do
          __eval("_#{name}_reset")
        end
        @@plugins[:main_case].each do |plugin|
          self.send(plugin, c)
        end
      end
    end
  end
end
