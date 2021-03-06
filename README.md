scimv2-pilot
============

Pilot Apex implementation of SCIM v2 client

Overview
--------
This project is a sample implementation of SCIM v2.

Getting Started
---------------
Use the [Salesforce Migration Tool](https://developer.salesforce.com/docs/atlas.en-us.daas.meta/daas/meta_development.htm) to install this unpackaged Apex. It will create a set of Apex REST web services that will act as your SCIM client. The SCIM endpoints will look like https://MYDOMAIN.my.salesforce.com/services/apexrest/scim/v2

There are 2 deployment targets: deploySCIM and deploySCIMWithIndividual. If you have enabled the [Individual] (https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_individual.htm) object use the second deployment target

Verbs and Endpoints
-------------------
This implementation supports the following endpoints:
* Users: /services/apexrest/scim/v2/Users
* Groups: /services/apexrest/scim/v2/Groups
* Roles: /services/apexrest/scim/v2/Roles
* Entitlements: /services/apexrest/scim/v2/Entitlements
* ResourceTypes: /services/apexrest/scim/v2/ResourceTypes
* ServiceProviderConfigs: /services/apexrest/scim/v2/ServiceProviderConfigs
* Schemas: /services/apexrest/scim/v2/Schemas
* Me: /servivices/apexrest/scim/v2/Me
* Individuals: /services/apexrest/scim/v2/Individuals

This implementation supports:
* GET against all endpoints
* PATCH, POST,PUT against all endpoints
* PATCH follows the PATCH Simple pattern and does not support filters
* POST-based search against /Users and /Individuals

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


