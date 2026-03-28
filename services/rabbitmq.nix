{ ... }:
{
  services.rabbitmq = {
    enable = true;
    port = 5672;
    plugins = [ "rabbitmq_consistent_hash_exchange" ];
    managementPlugin.enable = true;
  };

  services.redis = {
    enable = true;
    port = 6379;
  };
}
