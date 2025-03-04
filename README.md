# OpenTelemetry Tracing for Node.js Application

## Overview

This guide will help you integrate OpenTelemetry tracing into your Node.js application using [SigNoz](https://github.com/SigNoz/sample-nodejs-app). Follow the steps below to configure tracing and visualize data in SigNoz.

## Prerequisites

- Node.js installed
- Access to a SigNoz-hosted server
- Security group access to ports `4317` and `4318`

## Step 1: Create `tracing.js` in `src` directory

Create a file named `tracing.js` in the same directory as your `index.js` file and add the following content:

```javascript
'use strict';
import process from 'process';
import * as opentelemetry from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';

const exporterOptions = {
  url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318/v1/traces',
};

const traceExporter = new OTLPTraceExporter(exporterOptions);
const sdk = new opentelemetry.NodeSDK({
  traceExporter,
  instrumentations: [getNodeAutoInstrumentations()],
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'node_app'
  })
});

sdk.start();

process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('Tracing terminated'))
    .catch((error) => console.log('Error terminating tracing', error))
    .finally(() => process.exit(0));
});
```

## Step 2: Create a `.env` File

Create a `.env` file in the root directory and add your environment variables:

```env
DB_HOST=database-1.cxugm6u0ctx0.ap-southeast-2.rds.amazonaws.com
DB_USER=admin
DB_PASSWORD=admin123
DB_NAME=schooldb
REDIS_URL=redis://redis:6379
OTEL_EXPORTER_OTLP_ENDPOINT=http://3.106.54.202:4318/v1/traces
```

## Step 3: Install Dependencies

Run the following command to install OpenTelemetry dependencies:

```sh
npm install @opentelemetry/api \
    @opentelemetry/sdk-node \
    @opentelemetry/sdk-trace-node \
    @opentelemetry/auto-instrumentations-node \
    @opentelemetry/exporter-trace-otlp-http
```

## Step 4: Open Security Groups

Ensure that your security group allows inbound traffic to ports `4317` and `4318` on your SigNoz-hosted server.

## Step 5: Run Your Application

Start your Node.js application, and you should start seeing traces in SigNoz!

```bash
docker-compose up -d --build
```
## Visualize traces in signoz

<img width="1470" alt="Screenshot 2025-03-04 at 3 52 36 PM" src="https://github.com/user-attachments/assets/e0a45924-4793-4e3c-937c-0db9907220f3" />
<img width="1470" alt="Screenshot 2025-03-04 at 3 53 02 PM" src="https://github.com/user-attachments/assets/5b64e384-bea4-4afa-a3c9-15d94a99a5d5" />
<img width="1470" alt="Screenshot 2025-03-04 at 3 53 11 PM" src="https://github.com/user-attachments/assets/431fc238-ad42-4d42-a987-e41db1613e1c" />



## Troubleshooting

- Check if the SigNoz server is running and accessible.
- Verify that environment variables are correctly set.
- Ensure security group rules allow traffic on required ports.

## References

- [SigNoz Sample Node.js App](https://github.com/SigNoz/sample-nodejs-app)
