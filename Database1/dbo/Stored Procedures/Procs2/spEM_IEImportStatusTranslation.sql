CREATE PROCEDURE dbo.spEM_IEImportStatusTranslation
@LineDesc 	  	  	 nVarchar (100),
@UnitDesc 	  	  	 nVarchar (100),
@TEStatusName 	  	 nVarChar(100),
@TEStatusValue 	  	 nvarchar(25),
@UserId 	  	  	  	 int
As
Declare 	 @UnitId 	  	 Int,
 	 @LineId 	 Int,
 	 @TEStatusId Int
/* Clean arguments */
SELECT  	 @LineDesc  	 = RTrim(LTrim(@LineDesc)),
 	 @UnitDesc  	 = RTrim(LTrim(@UnitDesc)),
 	 @TEStatusName  	 = RTrim(LTrim(@TEStatusName)),
 	 @TEStatusValue  	 = RTrim(LTrim(@TEStatusValue))
IF @LineDesc = ''  	 SELECT @LineDesc = NULL
IF @UnitDesc = ''  	 SELECT @UnitDesc = NULL
IF @LineDesc Is Null
  BEGIN
 	 SELECT 'Failed - Production Line must be defined'
 	 Return (-100)
  END
IF @UnitDesc Is Null
  BEGIN
 	 SELECT 'Failed - Production Unit must be defined'
 	 Return (-100)
  END
  SELECT @LineId = Null
SELECT @LineId = Pl_Id FROM Prod_Lines WHERE pl_Desc = @LineDesc
IF @LineId Is Null
  BEGIN
 	 SELECT 'Failed - Production Line not found'
 	 Return (-100)
  END
SELECT @UnitId = Null
SELECT @UnitId = PU_Id FROM Prod_Units  WHERE pl_Id = @LineId and PU_Desc = @UnitDesc
IF @UnitId Is Null
  BEGIN
 	 SELECT 'Failed - Production Unit not found'
 	 Return (-100)
  END
SELECT @TEStatusId = TEStatus_Id FROM Timed_Event_Status WHERE TEStatus_Name = @TEStatusName and PU_Id = @UnitId 
EXECUTE spEM_PutTimedEventStatus   
 	  	  	 @UnitId,
 	  	  	 @TEStatusId,
 	  	  	 @TEStatusName,
 	  	  	 @TEStatusValue,
 	  	  	 @UserId
RETURN(0)
