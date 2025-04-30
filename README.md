# IPVault 📚🔐  
**Decentralized Intellectual Property Rights Management Smart Contract**

**IPVault** is a Clarity smart contract designed to empower creators, inventors, and innovators by allowing them to **register, manage, license, and monetize** their intellectual property (IP) securely and transparently on the blockchain.

---

## 🚀 Features

- **IP Registration**: Creators can register IP with immutable metadata and proof-of-ownership.
- **License Management**: Issue, revoke, and manage usage licenses for registered IP.
- **Royalty Distribution**: Automatically distribute royalties to creators based on licensing terms.
- **Usage Tracking**: Keep an on-chain record of all licensing transactions and usage history.
- **Ownership Transfer**: Support for sale or transfer of IP rights between users.

---

## 🛠️ Contract Functions

### `register-ip (ip-id principal) (ip-meta (string-utf8 256))`
Registers a new intellectual property item with unique metadata. Only callable by the original creator.

### `issue-license (ip-id principal) (licensee principal) (terms (string-utf8 256))`
Issues a license for a specific IP to a licensee with defined usage terms.

### `revoke-license (ip-id principal) (licensee principal)`
Revokes a previously issued license.

### `record-usage (ip-id principal) (licensee principal) (description (string-utf8 256))`
Logs an instance of IP usage by a licensee, useful for tracking or dispute resolution.

### `distribute-royalties (ip-id principal) (amount uint)`
Distributes a specified amount of royalties to the IP owner and any co-owners according to predefined splits.

### `transfer-ip (ip-id principal) (to principal)`
Transfers ownership of an IP item to another principal (e.g., in case of sale or inheritance).

---

## 📦 Data Structures

- **IP-Record**: Contains `creator`, `metadata`, `timestamp`, and `ownership info`.
- **License-Record**: Maps licensees to their granted permissions and terms.
- **Royalty-Schedule**: Defines how payments are split among stakeholders.

---

## 🧠 Use Cases

- Musicians licensing songs to platforms.
- Designers selling rights to their digital assets.
- Authors monetizing their works through royalties.
- Startups registering and managing patents or trademarks.

---

## 🔐 Security & Integrity

- All actions are verified against ownership and licensing rights.
- Immutable records ensure transparency and traceability.
- Role-based controls prevent unauthorized operations.

---

## 📄 License

This project is open-source under the [MIT License](https://opensource.org/licenses/MIT). Feel free to fork, audit, or contribute.

---

## 🤝 Contributing

We welcome contributions! If you'd like to suggest a feature or submit a pull request, please follow the standard GitHub contribution flow. For major changes, please open an issue first to discuss what you’d like to change.

---

## 🧩 Integrations

Coming soon:  
- Frontend dApp interface  
- Oracle integrations for real-world IP registries  
- NFT-based IP tokenization  