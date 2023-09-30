CREATE PROCEDURE dbo.spServer_CmnGetParmNames
 AS
select Parm_Id, Parm_Name from Parameters
