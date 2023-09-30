CREATE PROCEDURE dbo.spEMEPC_IsProductOnUnitsPath
@ProductId int,
@UnitId int,
@User_Id int
AS
Select *
From PrdExec_Path_Products P 
  Join PrdExec_Path_Units U ON P.Path_Id = U.Path_Id and Is_Schedule_Point = 1
Where Prod_Id = @ProductId 
  and PU_Id = @UnitId
