scimv2-pilot
============

Pilot Apex implementation of SCIM v2 client

Overview
--------
This project is a sample implementation of SCIM v2. It is the codebase that was used during the SCIM v2 Interop for CIS 2016.

Getting Started
---------------
Use the [Salesforce Migration Tool](https://developer.salesforce.com/docs/atlas.en-us.daas.meta/daas/meta_development.htm) to install this unpackaged Apex. It will create a set of Apex REST web services that will act as your SCIM client. The SCIM endpoints will look like https://MYDOMAIN.my.salesforce.com/services/apexrest/scim/v2

Verbs and Endpoints
-------------------
This implementation supports the following endpoints:
* Users: /services/apexrest/scim/v2/Users
* Groups: /services/apexrest/scim/v2/Groups
* Roles: /services/apexrest/scim/v2/Roles
* Entitlements: /services/apexrest/scim/v2/Entitlements
* ServiceProviderConfigs: /services/apexrest/scim/v2/ServiceProviderConfigs
* Schemas: /services/apexrest/scim/v2/Schemas

This implementation supports:
* GET against all endpoints
* POST and PUT against /Users
* /Users also has preliminary support for PATCH as does /Groups and /Entitlements - Use with caution. Keep in mind this implementation does not support filters in path attributes of PATCH operations
* POST-based search against /Users

Creating External Users
-----------------------
This implementation can create external users. In order to do so, you must:
* Specify a Profile (as an Entitlement) of the correct type e.g. External Identity, Customer Community, etc
* If you are using Person Accounts, then you do not need to specify anything else. For example:

`{
	"schemas": [
		"urn:scim:schemas:core:1.0",
		"urn:scim:schemas:extension:enterprise:1.0",
		"urn:salesforce:schemas:extension:1.0"		
	],
	"userName": "puser12@scimv2.com",
	"externalId": "puser12@scimv2.com",
	"name": {
		"familyName": "PersonAccount12",
		"givenName": "Ima"
	},
	"nickName": "puser12",
	"emails": [
		{
			"type": "work",
			"primary": true,
			"value": "puser12@scimv2.com"
		}
	],
	"locale": "en_US",
	"active": true,
	"entitlements": [
		{
			"value": "00e36000001Bu39"
		}
	],
	"urn:salesforce:schemas:extension:1.0":{
		"alias":"puser12"
	}
}`

* If you are using Business Accounts, then you will need to include a valid urn:salesforce:schemas:extension:external:1.0:accountId which maps to the ID of the Salesforce Account in which you'd like to create the associated Contact object. For example:

`{
	"schemas": [
		"urn:scim:schemas:core:1.0",
		"urn:scim:schemas:extension:enterprise:1.0",
		"urn:salesforce:schemas:extension:1.0"		
	],
	"userName": "puser12@scimv2.salesforceidentity.info",
	"externalId": "puser12@salesforce.com",
	"name": {
		"familyName": "PersonAccount12",
		"givenName": "Ima"
	},
	"nickName": "puser12",
	"emails": [
		{
			"type": "work",
			"primary": true,
			"value": "iglazer@salesforce.com"
		}
	],
	"locale": "en_US",
	"active": true,
	"entitlements": [
		{
			"value": "00e36000001Bu39"
		}
	],
	"urn:salesforce:schemas:extension:1.0":{
		"alias":"puser12"
	},
	"urn:salesforce:schemas:extension:external:1.0": {
		"accountId": "0013600000Q1hmz",
	}
}`


