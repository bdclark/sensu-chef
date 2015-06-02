action :create do
  definitions = Sensu::Helpers.select_attributes(
    node.sensu,
    %w[transport rabbitmq redis api]
  )

  data_bag_name = node.sensu.data_bag.name
  config_item_key = node.sensu.data_bag.config_item

  config = Sensu::Helpers.config_item(node, config_item_key, data_bag_name)

  if config
    definitions = Chef::Mixin::DeepMerge.merge(definitions, config.to_hash)
  end

  service_config = {}

  %w[
    client
    api
    server
  ].each do |service|
    unless node.recipe?("sensu::#{service}_service") ||
        node.recipe?("sensu::enterprise_service")
      next
    end

    service_config_item = Sensu::Helpers.config_item(node, service, data_bag_name)

    if service_config_item
      service_config = Chef::Mixin::DeepMerge.merge(service_config, service_config_item.to_hash)
    end
  end

  unless service_config.empty?
    definitions = Chef::Mixin::DeepMerge.merge(definitions, service_config)
  end

  if definitions['rabbitmq'] && definitions['rabbitmq']['host'].is_a?(Array)
    rabbitmq_config = definitions.delete('rabbitmq')
    definitions['rabbitmq'] = []
    rabbitmq_config['host'].each do |host|
      definitions['rabbitmq'] << rabbitmq_config.merge({ 'host' => host })
    end
  end

  f = sensu_json_file ::File.join(node.sensu.directory, "config.json") do
    content Sensu::Helpers.sanitize(definitions)
  end

  new_resource.updated_by_last_action(f.updated_by_last_action?)
end
