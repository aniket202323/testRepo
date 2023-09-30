Create Procedure dbo.spAL_ListSecurityGroups AS
  SELECT * FROM SECURITY_GROUPS ORDER BY GROUP_DESC
