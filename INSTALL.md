# Installation

The recommended way to use these lists is by adding the Raw GitHub URLs directly to Pi-hole. This allows Pi-hole to automatically download the latest version of each list whenever Gravity is updated.

## Add a Blocklist

1. Open the Pi-hole Admin Interface.
2. Navigate to **Group Management → Adlists**.
3. Click **Add a new adlist**.
4. Paste the Raw GitHub URL of the desired list.
5. Click **Add**.
6. Repeat the process for any additional lists.

## Update Gravity

Once all lists have been added, update Gravity from:

**Tools → Update Gravity**

or via SSH:

```bash
pihole -g
```

Pi-hole will download the latest version of each list and apply the changes automatically.

## Updating

No manual updates are required.

Whenever you update Gravity (either from the web interface or by running `pihole -g`), Pi-hole will automatically fetch the latest version of all lists from this repository.

## Verify

To verify that everything is working correctly:

```bash
pihole status
```

You can also monitor the Pi-hole logs:

```bash
pihole -t
```
