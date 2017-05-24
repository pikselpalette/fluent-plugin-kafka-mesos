require 'faraday'
require 'json'

require 'fluent/output'
require 'fluent/plugin/out_kafka_buffered'

class Fluent::MesosKafkaOutput < Fluent::KafkaOutputBuffered
  Fluent::Plugin.register_output('kafka_mesos', self)

  config_param :broker_discovery,
               :desc => <<-DESC
Discover brokers via mesos-kafka API
http://kafka-mesos.example.com:9000/api/brokers/list
DESC

  def enumerate_brokers
    log.info "getting brokers from #{@broker_discovery}"
    response = Faraday.get @broker_discovery
    ret = JSON.load(response.body)
    @seed_brokers = ret['brokers'].each.map { |x| x['task']['endpoint'] }
    @brokers = @seed_brokers.join(',')
  end

  def refresh_client(raise_error = true)
    enumerate_brokers
    super
  end

  def configure(conf)
    super
    enumerate_brokers
    log.info "brokers have been discovered: #{@brokers}"
  end

  def emit(tag, es, chain)
    super(tag, es, chain)
  end
end
