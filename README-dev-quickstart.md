# Local dev quickstart (Emulator)
1. Install deps: `cd functions && npm install`
2. Use Node 18: `nvm use 18`
3. Start emulators: `npx firebase-tools emulators:start`
4. In another terminal:
   - `cd functions`
   - `export FIRESTORE_EMULATOR_HOST=localhost:8080`
   - `export GCLOUD_PROJECT=<your-project-id>`
   - `node test-firestore.js`
