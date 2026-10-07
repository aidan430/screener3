# Setup: from nothing to a factory that runs itself

Do one step at a time. Each step says what it is, what to tap, and how you know it is done.

**Golden rule:** keys and passwords never go into a chat, an email or GitHub. They go into
your password app, and from there into your own server (step 4 shows how).

**Money fences you are setting up:** prepaid Claude credit, a $50 monthly limit, the
factory's R50-a-day limit, R700 per smoke test, R10,000 per first stock batch and R15,000
per product's whole start-up. Nothing is bought without your tap.

## Stage A: switch it on

### 1. Claude key: the factory's brain (10 minutes)
The agents are Claude. Each time one thinks, Anthropic charges a few cents. The key is like
a library card that says "put it on my account".
1. Go to console.anthropic.com (it moves you to platform.claude.com, the same place) and sign up.
2. Billing, then Buy credits: buy $20 (about R370). Leave auto-reload off.
3. Settings, then Limits: set a monthly spend limit of $50.
4. API keys, then Create key: name it `factory` and copy it. It starts with `sk-ant-`.
5. Save it in your phone's notes or password app.

Done when: you have $20 of credit and a saved key that starts with `sk-ant-`.

### 2. A domain: the factory's street address (10 minutes, about R100-R250 a year)
Customers will see it on test pages, so pick a short, neutral name (not "factory" or "test").
1. Buy it from any registrar where you can edit "DNS records": a .co.za from a South African
   registrar, or a .com from Namecheap or Cloudflare.
2. Find its DNS settings page. You will add two lines there in step 3.

Done when: you own the domain and can see its DNS settings page.

### 3. A server: a computer that never sleeps (15 minutes, about $6 / R110 a month)
1. Sign up at digitalocean.com and add your card.
2. Create, then Droplets. Region: London. Image: Ubuntu 24.04 (LTS).
   Size: Basic, Regular, $6 a month.
3. Authentication: Password. Make a long one, save it in your password app.
4. Hostname: `factory`. Tap Create Droplet and wait a minute.
5. Copy the droplet's IPv4 address (four numbers with dots, like 164.90.12.34).
6. On your domain's DNS page add two "A" records, both pointing at that address:
   - Host `@` (the domain itself), value: the IPv4 address
   - Host `admin`, value: the same address

Done when: the droplet shows "Active" and both A records are saved. They can take up to
30 minutes to work; you can carry on meanwhile.

### 4. Install the factory: one command (15 minutes, best on a laptop)
1. On GitHub, open aidan430/screener3, Pull requests, #1, then **Merge pull request** and
   **Confirm**. This makes the finished code the version your server installs.
2. On DigitalOcean, open your droplet, then **Access**, then **Launch Droplet Console**.
   A black window opens: that is your server.
3. Copy this whole line, paste it into that window and press Enter:

   ```
   curl -fsSL https://raw.githubusercontent.com/aidan430/screener3/main/scripts/install.sh | bash
   ```
4. It asks two things: paste your Claude key (you will not see it while you paste; that is
   on purpose) and type your domain (like `mytrials.co.za`).
5. Wait 3 to 5 minutes. At the end it shows your **dashboard password once**. Save it in
   your password app straight away.
6. Open `https://admin.yourdomain` on your phone. Log in with user `owner` and that password.

Done when: you see the arena with its six camps. If the page does not open yet, the A
records from step 3 are still travelling; try again in 15 minutes.

### 5. A Reddit app: so the scouts can listen (5 minutes)
1. Log in to Reddit, open reddit.com/prefs/apps, tap "create another app".
2. Name `venture-factory`, choose **script**, redirect uri `http://localhost:8080`. Create.
   If Reddit asks what it is for: a personal research tool that reads public posts.
3. The short code under the app name is the ID; "secret" is the secret.
4. In the droplet console, run these one at a time and paste each value when asked:
   ```
   bash /opt/factory/screener3/scripts/set-key.sh REDDIT_CLIENT_ID
   bash /opt/factory/screener3/scripts/set-key.sh REDDIT_CLIENT_SECRET
   bash /opt/factory/screener3/scripts/set-key.sh REDDIT_USER_AGENT
   ```
   For the last one type `venture-factory/0.1 by u/` followed by your Reddit username.

Done when: each one says "Saved ... and restarted the factory".

### 6. Email for the Monday report (5 minutes, optional)
1. In your Google account turn on 2-Step Verification, then create an **App password**
   named `factory`. You get 16 letters.
2. Run `set-key.sh` (as in step 5) for each of these:
   `SMTP_HOST` = `smtp.gmail.com`, `SMTP_PORT` = `587`, `SMTP_USER` = your Gmail address,
   `SMTP_PASSWORD` = the 16 letters, `REPORT_EMAIL_TO` = where the report should go.

Done when: the dashboard's Warden panel button "WRITE REPORT NOW" sends you an email.

## Stage B: start the slow ones now (they take days to approve)

### 7. Paystack: how you get paid
1. Sign up at paystack.com for South Africa and finish the checks (your ID, your bank account).
2. Once approved: Settings, API Keys & Webhooks. Copy the **secret key** and save it with
   `set-key.sh PAYSTACK_SECRET_KEY`.
3. Set the webhook URL to `https://yourdomain/api/paystack/webhook`.

### 8. Quotes for the warehouse and for imports
Ask a South African fulfilment warehouse (for example Parcel Ninja) and a clearing agent or
freight forwarder for quotes. Say: a small online store starting with 30-40 units of one
small product under 1 kg, later 5-20 orders a day, on Shopify. Ask for:
- warehouse: setup fee, receiving per unit, storage per unit a month, pick and pack per
  order, packaging, courier rates (door to door and lockers), returns handling;
- imports: air freight per kg from China to Johannesburg, clearing fee per shipment, and
  whether you need a SARS customs client number.

Send me the numbers (they are not secret). I will put them into `config/commerce.yaml`, so
every product is costed with your real prices instead of my estimates.

### 9. A Facebook ad account: for the smoke tests
1. At business.facebook.com create a business portfolio, then an ad account in rand
   (ZAR) on South African time.
2. Add your card. Facebook may ask for your ID.
For now you create each test's three ads by hand from the steps the dashboard shows after
FUND TEST (about 10 minutes a test).

### 10. Etsy and eBay keys: for price research
- etsy.com/developers: create an app and save its key with `set-key.sh ETSY_API_KEY`.
- developer.ebay.com: create production keys and save the App ID with
  `set-key.sh EBAY_CLIENT_ID` and the Cert ID with `set-key.sh EBAY_CLIENT_SECRET`.
  If eBay asks about account-deletion notices, say you do not store eBay user data.

## Stage C: only when a product wins

The arena shows the product at tower 6 with a **FUND STOCK** button. Tapping it buys
nothing: it gives you a shopping list and writes a draft first order. Then:
1. Order 3 samples. Hold them, check quality and weight, and check the product needs no
   ICASA, NRCS or SAHPRA approval.
2. Open a Shopify store and connect Paystack and the warehouse's Shopify app.
3. Place the first order with the supplier, delivered to the warehouse's inbound address.

## Everyday use
- Dashboard: `https://admin.yourdomain` (user `owner`). Check it when the Monday report
  arrives; it lists every decision waiting for you.
- Your taps: FUND TEST (then make the ads), FUND STOCK, RETRY TRAINING, and "I handled it"
  on alerts.
- Updates: when I build something new I open a pull request. Merge it, then paste the
  install command from step 4 again. It keeps your settings.

## If something goes wrong
- **The dashboard will not open:** check both A records point at the droplet's address,
  then wait 15-30 minutes.
- **Forgot the dashboard password:** in the droplet console run
  `bash /opt/factory/screener3/scripts/set-key.sh DASHBOARD_PASSWORD` and type a new one.
- **Is it running?** `systemctl status factory-web factory-scheduler` (look for
  "active (running)").
- **What went wrong?** `journalctl -u factory-scheduler -n 50` shows the last 50 lines.
  Copy them to me, after checking they contain no keys.
