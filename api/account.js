// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

// /api/account - player accounts and cloud saves (Vercel serverless function).
//
// Data lives in a PRIVATE Vercel Blob store (BLOB_READ_WRITE_TOKEN is only
// on the server). See api/_lib/account-handler.js for the routes and
// api/_lib/accounts.js for how passwords, emails and sessions are protected.

import { createAccountHandler } from './_lib/account-handler.js';
import { createBlobStore } from './_lib/store.js';

export default createAccountHandler({ store: createBlobStore() });
