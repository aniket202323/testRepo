CREATE PROCEDURE [dbo].[spBF_APIMyMachines_AuthorizedUnitsAndEventTypes]
(@UserId INT)
AS
BEGIN
 	 -- SET NOCOUNT ON added to prevent extra result sets from
 	 -- interfering with SELECT statements.
 	 SET NOCOUNT ON;
DECLARE @OutputResult TABLE
(Dept_Id BIGINT, Dept_Desc nVarChar(max), PL_Id BIGINT, PL_Desc nVarChar(max), PU_Id BIGINT, PU_Desc nVarChar(max), ET_Id BIGINT, ET_Desc nVarChar(max))
INSERT INTO @OutputResult (Dept_Id, Dept_Desc, PL_Id, PL_Desc, PU_Id, PU_Desc, ET_Id,ET_Desc)
 	 select Dept_Id, Dept_Desc, PL_Id, PL_Desc, PU_Id, PU_Desc, ET_Id,ET_Desc from fnBF_ApiFindAvailableUnitsAndEventTypes(@UserId);
select * from @OutputResult
END
