CREATE PROCEDURE dbo.spNP_InsertPreCheck
 	   @UnitString1 	 Varchar(8000)
 	 , @UnitString2 	 Varchar(8000)
 	 , @Start_Time 	 DateTime
 	 , @End_Time 	     DateTime
 	 , @TotalCount 	 Int Output
AS
DECLARE @Units TABLE  (Id Int Identity(1,1),PUId integer)
INSERT  INTO @Units(PUId) 
 	 SELECT Id FROM  fnCMN_IdListToTable('Prod_Units',@UnitString1,'$')
INSERT  INTO @Units(PUId) 
 	 SELECT Id FROM  fnCMN_IdListToTable('Prod_Units',@UnitString2,'$')
SELECT @TotalCount = Count(*) - 1
  FROM NonProductive_Detail d
  JOIN Prod_Units pu ON pu.PU_Id = d.PU_Id AND pu.PU_Id <> 0 AND pu.Non_Productive_Category = 7
  JOIN @Units t ON t.ID = d.PU_Id AND d.Start_Time BETWEEN @Start_Time AND @End_Time AND d.End_Time <= @End_Time
