Create Procedure dbo.spSS_EventSimpleSearch
 @PUId Int = NULL,
 @EventNum nVarChar(50) = NULL,
 @PrdExecPathFlg Int,
 @PrdExecLinkDirection Int,
 @RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
Declare @SQLCommand Varchar(4500),
 	  	 @SQLCond0 nVarChar(1024),
 	  	 @FlgAnd int,
 	  	 @FlgFirst int
If (@PUId Is Not Null and @PUId <> 0)
BEGIN
 	 CREATE TABLE #ProdUnits (PU_Id int)
 	 If (@PrdExecPathFlg Is Null or @PrdExecPathFlg = 0)
 	 BEGIN
 	  	 Insert into #ProdUnits (PU_Id) values (@PUId) --Only 1 specific Unit
 	 END
 	 ELSE
 	 BEGIN
 	  	 If @PrdExecLinkDirection = 0 --Parent Search
 	  	 BEGIN
 	          Insert into #ProdUnits (PU_Id)
 	  	  	  	 Select pis.pu_id
 	  	  	  	 from PrdExec_Inputs pi
 	  	  	  	 join PrdExec_Input_Sources pis on pi.PEI_Id = pis.PEI_Id
 	  	  	  	 Where pi.PU_Id = @PUId
 	  	 END
 	  	 ELSE --Children Search
 	  	 BEGIN 
           Insert into #ProdUnits (PU_Id)
 	  	  	  	 Select distinct pi.pu_id 
 	  	  	  	 From PrdExec_Input_Sources pis
 	  	  	  	 join PrdExec_Inputs pi on pi.PEI_Id = pis.PEI_Id
 	  	  	  	 Where pis.PU_id = @PUId
         END
 	 END
END
---------------------------------------------
-- Initialize variables
---------------------------------------------
 Select @FlgFirst= 0
 Select @FlgAnd = 0
 Select @SQLCOnd0 = NULL
IF @RegionalServer = 1
BEGIN
 	 Select @SQLCommand = 'Select [Event Number] = E.Event_Num , [Unit] = P.PU_Desc, [TimeStamp] = E.TimeStamp, ' +
                      '[Status] = PS.ProdStatus_Desc, E.Event_Id, P.PU_Id ' +
                      'From Events E ' +
                      'Join Production_Status PS on PS.ProdStatus_Id = E.Event_Status '
END
ELSE
BEGIN
 	 Select @SQLCommand = 'Select E.Event_Num as "Event Num", P.PU_Desc as "Unit", E.TimeStamp as "Time Stamp", ' +
 	  	  	  	  	  	   'PS.ProdStatus_Desc as "Status", E.Event_Id, P.PU_Id ' +
 	  	  	  	  	  	   'From Events E ' +
 	  	  	  	  	  	   'Join Production_Status PS on PS.ProdStatus_Id = E.Event_Status '
END
If (@PUId Is Not Null and @PUId <> 0)
BEGIN
 	 Select @SQLCommand = @SQLCommand + 'Join #ProdUnits P2 on P2.PU_Id = E.PU_Id '
 	 Select @SQLCommand = @SQLCommand + 'Join Prod_Units P on P.PU_Id = E.PU_Id'
END
ELSE
BEGIN
 	 Select @SQLCommand = @SQLCommand + 'Join Prod_Units P on P.PU_Id = E.PU_Id'
END
-------------------------------------------------------------------
-- EventNum
-----------------------------------------------------------------------
If (@EventNum Is Not Null And Len(@EventNum)>0)
BEGIN
 	 Select @SQLCond0 = "E.Event_Num Like '%" + @EventNum + "%'"
 	 If (@FlgAnd=1)
 	 BEGIN
 	  	 Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
 	 END
 	 ELSE
 	 BEGIN
 	  	 Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
 	  	 Select @FlgAnd = 1  
 	 END 
END  
Select @SQLCommand = @SQLCommand + ' Order by E.TimeStamp Desc'
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T Table  (TimeColumns nVarChar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @T(TimeColumns) Values ('TimeStamp')
 	 Insert into @CHT(HeaderTag,Idx) Values (16334,1) -- Event Number
 	 Insert into @CHT(HeaderTag,Idx) Values (16304,2) -- Unit
 	 Insert into @CHT(HeaderTag,Idx) Values (16335,3) -- TimeStamp
 	 Insert into @CHT(HeaderTag,Idx) Values (16313,4) -- Status
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
END
Set RowCount 100 --Maximum of 100 rows in result set
Exec (@SQLCommand)
Set RowCount 0 --Turn off
--Clean up
If (@PUId Is Not Null and @PUId <> 0)
 	 Drop Table #ProdUnits
