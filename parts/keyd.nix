{ ... }:
{
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        # copilot key
        ids = [ "0001:0001:70533846" ];
        settings = {
          main = {
            ## taking the key combination from the monitor command and remapping it to meta / super key
            "leftshift+leftmeta+f23" = "layer(space)";
          };
        };
      };
    };
  };
}
