# Secrets

API keys and other secrets are managed via [agenix](https://github.com/ryantm/agenix).

The actual encrypted `.age` files live in the private `~/secrets/` repository.

To add a new secret:
1. Create the secret file: `age -e -r $(cat ~/.ssh/agenix_key.pub) -o ~/secrets/kilocode-api-keys.age`
2. Reference it in the Nix config under `age.secrets`
3. Rebuild the host
