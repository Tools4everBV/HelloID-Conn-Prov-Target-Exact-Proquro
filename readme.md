# HelloID-Conn-Prov-Target-Exact-Proquro

<!--
** for extra information about alert syntax please refer to [Alerts](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#alerts)
-->

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="https://www.tools4ever.nl/connector-logos/exactproquro-logo.png">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-Exact-Proquro](#helloid-conn-prov-target-exact-proquro)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Supported features](#supported-features)
  - [Getting started](#getting-started)
    - [HelloID Icon URL](#helloid-icon-url)
    - [Requirements](#requirements)
    - [Connection settings](#connection-settings)
    - [Correlation configuration](#correlation-configuration)
    - [Field mapping](#field-mapping)
    - [Account Reference](#account-reference)
  - [Remarks](#remarks)
    - [V1 to V2 conversion](#v1-to-v2-conversion)
    - [Not tested against Exact Proquro](#not-tested-against-exact-proquro)
  - [Development resources](#development-resources)
    - [API endpoints](#api-endpoints)
    - [API documentation](#api-documentation)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-Exact-Proquro_ is a _target_ connector. _Exact Proquro_ provides a set of REST APIs that allow you to programmatically interact with its data. The connector creates and updates user accounts in Exact Proquro.

## Supported features

The following features are available:

| Feature                                   | Supported | Actions | Remarks                                                          |
| ----------------------------------------- | --------- | ------- | ---------------------------------------------------------------- |
| **Account Lifecycle**                     | ✅         | Create  | Only create exists. Update, Enable, Disable and Delete are not implemented |
| **Permissions**                           | ❌         | -       |                                                                  |
| **Resources**                             | ❌         | -       |                                                                  |
| **Entitlement Import: Accounts**          | ❌         | -       |                                                                  |
| **Entitlement Import: Permissions**       | ❌         | -       |                                                                  |
| **Governance Reconciliation Resolutions** | ❌         | -       |                                                                  |

## Getting started

### HelloID Icon URL
URL of the icon used for the HelloID Provisioning target system.
```
https://raw.githubusercontent.com/Tools4everBV/HelloID-Conn-Prov-Target-Exact-Proquro/refs/heads/main/Icon.png
```

### Requirements

- **API key**:<br>
  The API key must be retrieved from within Exact Proquro.
- **Windows PowerShell 5.1**:<br>
  When using the HelloID On-Premises agent, Windows PowerShell 5.1 must be installed. The connector supports both Windows PowerShell 5.1 and PowerShell Core, so it can run in the cloud and on-premises. Older versions of Windows PowerShell are not supported.

### Connection settings

The following settings are required to connect to the API.

| Setting  | Description                                                                              | Mandatory |
| -------- | ---------------------------------------------------------------------------------------- | --------- |
| UserName | The user name to connect to Exact Proquro                                                | Yes       |
| Password | The password that belongs to the user name, used to retrieve the access token            | Yes       |
| ApiKey   | The API key used to authenticate. This must be retrieved from within the application     | Yes       |
| BaseUrl  | The URL to connect to Exact Proquro                                                      | Yes       |

### Correlation configuration

Correlation is not used. The create call (`/api/User/Update`) creates the user or updates an existing one, so the connector does not look up an existing account first. Whether the endpoint really behaves like that is not confirmed, see [Not tested against Exact Proquro](#not-tested-against-exact-proquro).

> [!TIP]
> _For more information on correlation, please refer to our correlation [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html) pages_.

### Field mapping

The field mapping can be imported by using the [fieldMapping.json](fieldMapping.json) file. No password is mapped: add a password field if Exact Proquro requires one.

### Account Reference

The account reference is the `externalId` returned by Exact Proquro. When the response has no `externalId`, the mapped `externalID` is used. Create fails when both are empty.

## Remarks

### V1 to V2 conversion

- **Settings:** the `Enable TLS 1.2` option is removed, TLS 1.2 is always enabled.
- **Behaviour changed:** V1 sent an empty `password`; V2 does not set a password. Add a password field to the mapping if the target requires it. The V1 create has no lookup of an existing account, so V2 create has no GET and no correlation step.
- **V1 bugs fixed:** the token request had `$body` instead of `Body`, no `POST`, a malformed form body, and used the whole response instead of `access_token` in the Bearer header.
- **Open questions:** see [Not tested against Exact Proquro](#not-tested-against-exact-proquro). Only create exists; update, enable, disable and delete are not implemented.

### Not tested against Exact Proquro

This connector has not been tested on an Exact Proquro implementation. Changes might have to be made to the code according to your requirements. The script was run against a mock API only, never the real API.

- **Confirmed:** the token property is `access_token`, with the form fields `grant_type`, `username`, `password` and `apikey`. The API property names are as mapped (`externalID`, `firstName`, `middleInitials`, `surName`, `loginName`).
- **Not confirmed (needs the API documentation or the vendor):**
  - Whether `/api/User/Update` is an upsert on `externalId` and returns `externalId`.
  - Whether an empty `profileUserExternalId` is accepted, and whether a disabled status can be set on create. A new account is created `active`.
  - Whether a password is required when `passwordMustChange` is true.

## Development resources

### API endpoints

The following endpoints are used by the connector

| Endpoint        | HTTP Method | Description                                           |
| --------------- | ----------- | ----------------------------------------------------- |
| /token          | POST        | Retrieve the access token                             |
| /api/User/Update | POST       | Create (or update) a user                             |

### API documentation

No public API documentation is available.

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
