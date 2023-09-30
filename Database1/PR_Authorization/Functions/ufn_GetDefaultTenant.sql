-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- FUNCTION: ufn_GetDefaultTenant

-- Return the default tenant GUID.  Used by the PersonnelMigration stored procedures.

CREATE FUNCTION [PR_Authorization].[ufn_GetDefaultTenant] ()
RETURNS UNIQUEIDENTIFIER
AS
BEGIN

   RETURN (SELECT TenantId
				FROM [PR_Authorization].Tenant
				WHERE Name = 'Root System Tenant')

END