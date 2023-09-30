CREATE Procedure dbo.spEMEPC_PutPathUnits
@PU_Id int,
@Path_Id int,
@Is_Schedule_Point bit,
@Is_Production_Point bit,
@Unit_Order int,
@User_Id int,
@PEPU_Id int = NULL OUTPUT
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_PutPathUnits',
             isnull(Convert(nVarChar(10),@PU_Id),'Null') + ','  + 
             isnull(Convert(nVarChar(10),@Path_Id),'Null') + ','  + 
             isnull(Convert(nvarchar(50),@Is_Schedule_Point),'Null') + ','  + 
             isnull(Convert(nvarchar(50),@Is_Production_Point),'Null') + ','  + 
             isnull(Convert(nVarChar(10),@Unit_Order),'Null') + ','  + 
             isnull(Convert(nVarChar(10),@User_Id),'Null') + ','  + 
             isnull(Convert(nVarChar(10),@PEPU_Id),'Null'), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Declare @Prod_Id int
If @PEPU_Id is NULL
  Begin
    Select @Is_Schedule_Point = Case When Count(*) > 0 Then 0 Else 1 End From PrdExec_Path_Units Where Path_Id = @Path_Id and Is_Schedule_Point = 1
    Insert Into PrdExec_Path_Units (PU_Id, Path_Id, Is_Schedule_Point, Is_Production_Point, Unit_Order)
      Values (@PU_Id, @Path_Id, @Is_Schedule_Point, @Is_Production_Point, @Unit_Order)
    Select @PEPU_Id = Scope_Identity()
 	  	 If @Is_Schedule_Point = 1
 	  	  	 Begin
        Delete From PrdExec_Path_Products Where Path_Id = @Path_Id
 	  	     Declare ProductsCursor Cursor For
 	  	       Select Prod_Id From PU_Products Where PU_Id = @PU_Id For Read Only
 	  	     Open ProductsCursor
 	  	     While (0=0) Begin
 	  	       Fetch Next
 	  	         From ProductsCursor
 	  	         Into @Prod_Id
 	  	       If (@@Fetch_Status <> 0) Break
 	  	  	  	  	  	 If (Select Count(*) From PrdExec_Path_Products Where Path_Id = @Path_Id and Prod_Id = @Prod_Id) = 0
 	  	  	         Insert Into PrdExec_Path_Products (Path_Id, Prod_Id) Values (@Path_Id, @Prod_Id)
 	  	     End
 	  	     Close ProductsCursor
 	  	     Deallocate ProductsCursor
 	  	 End
  End
Else If @PEPU_Id is NOT NULL and @Path_Id is NOT NULL
  Begin
    Declare @Other_PEPU_Id int, @Other_Unit_Order int
    Select @Other_Unit_Order = Unit_Order From PrdExec_Path_Units Where PEPU_Id = @PEPU_Id
    Select @Other_PEPU_Id = PEPU_Id From PrdExec_Path_Units Where Unit_Order = @Unit_Order and Path_Id = @Path_Id
    Update PrdExec_Path_Units Set Unit_Order = @Other_Unit_Order Where PEPU_Id = @Other_PEPU_Id
    If @Is_Schedule_Point = 1
      Delete From PrdExec_Path_Products Where Path_Id = @Path_Id
 	     Declare ProductsCursor2 Cursor For
 	       Select Prod_Id From PU_Products Where PU_Id = @PU_Id For Read Only
 	     Open ProductsCursor2
 	     While (0=0) Begin
 	       Fetch Next
 	         From ProductsCursor2
 	         Into @Prod_Id
 	       If (@@Fetch_Status <> 0) Break
 	  	  	  	  	 If (Select Count(*) From PrdExec_Path_Products Where Path_Id = @Path_Id and Prod_Id = @Prod_Id) = 0
 	  	         Insert Into PrdExec_Path_Products (Path_Id, Prod_Id) Values (@Path_Id, @Prod_Id)
 	     End
 	     Close ProductsCursor2
 	     Deallocate ProductsCursor2
 	  	  	 If @Is_Schedule_Point = 1 and (Select Is_Schedule_Point From PrdExec_Path_Units Where PEPU_Id = @PEPU_Id) = 0
 	  	  	  	 Update PrdExec_Path_Units Set Is_Schedule_Point = 0 Where Path_Id = @Path_Id and Is_Schedule_Point = 1 and PEPU_Id <> @PEPU_Id
      Update PrdExec_Path_Units 
      Set Is_Schedule_Point = @Is_Schedule_Point, Is_Production_Point = @Is_Production_Point, Unit_Order = @Unit_Order
      Where PEPU_Id = @PEPU_Id
  End
Else If @PEPU_Id is NOT NULL and @Path_Id is NULL
  Begin
    Select @Path_Id = Path_Id, @Unit_Order = Unit_Order from PrdExec_Path_Units Where PEPU_Id = @PEPU_Id
    Update PrdExec_Path_Units set Unit_Order = Unit_Order - 1 Where Path_Id = @Path_Id and Unit_Order > @Unit_Order
    Delete From PrdExec_Path_Units
      Where PEPU_Id = @PEPU_Id
    If (Select Count(*) From PrdExec_Path_Units Where Path_Id = @Path_Id and Is_Schedule_Point = 1) = 0 and (Select Count(*) From PrdExec_Path_Units Where Path_Id = @Path_Id) > 0
      Update PrdExec_Path_Units Set Is_Schedule_Point = 1 Where Path_Id = @Path_Id and Unit_Order = (Select Min(Unit_Order) From PrdExec_Path_Units Where Path_Id = @Path_Id)
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
