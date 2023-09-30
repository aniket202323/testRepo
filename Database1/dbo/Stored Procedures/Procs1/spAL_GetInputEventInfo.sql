-----------------------------------------------------------
-- Type: Stored Procedure
-- Name: spAL_GetInputEventInfo
-----------------------------------------------------------
CREATE PROCEDURE dbo.spAL_GetInputEventInfo
@ComponentId int,
@PUId int OUTPUT,
@StartTime datetime OUTPUT,
@EndTime datetime OUTPUT,
@PEIId int OUTPUT
AS 
/***********************************************************/
/******** Copyright 2004 GE Fanuc International Inc.********/
/****************** All Rights Reserved ********************/
/***********************************************************/
Declare
  @EventId int,
  @SourceEventId int,
  @SourcePUId int
Select @EventId = NULL
Select @PUId = NULL
Select @StartTime = NULL
Select @EndTime = NULL
Select @PEIId = NULL
SELECT @SourcePUId = NULL
Select @EventId = EC.Event_Id,
       @SourceEventId = EC.Source_Event_Id,
       @StartTime = EC.Start_Time,
       @EndTime = EC.Timestamp,
       @SourcePUId = EV.PU_Id
  From Event_Components EC
  Join Events EV
  ON   EC.Source_Event_Id = EV.Event_Id
  Where Component_Id = @ComponentId
If (@EventId Is Not NULL) And (@EndTime Is Not NULL)
  Begin
    Select @PUId = PU_Id From Events Where Event_Id = @EventId
    Select @PEIId = PEI_Id From PrdExec_Input_Event_History
      Where (PEIP_Id = 1) And 
            (Event_Id = @SourceEventId) --And 
            --(Timestamp = @EndTime)
      -------------------------------------------------------------------------
      -- If there are not any load movements, it still should be able to find 
      -- the PEIId. If the Parent PU belongs to multiple raw material inputs, then
      -- the SP can not decide which one to pick
      -- 
      -- AJ 25-Nov-2004
      ------------------------------------------------------------------------- 	  	 
      If (@PEIId Is Null)
      Begin
       If (Select Count(PEIS_Id)
           From PrdExec_Input_Sources PIS
           Join PrdExec_Inputs PI
 	    On PIS.PEI_Id = PI.PEI_Id
           And PI.PU_Id = @PUId
           And PIS.PU_Id = @SourcePUId) = 1 
 	    Begin
            Select @PEIId = PI.PEI_Id
             From PrdExec_Input_Sources PIS
             Join PrdExec_Inputs PI
 	      On PIS.PEI_Id = PI.PEI_Id
             And PI.PU_Id = @PUId
             And PIS.PU_Id = @SourcePUId
 	    End 	 
      End 	  	  	 
  End
-----------------------------------------------------------------------------
-- TODO: figure out the starttime. It should be the end time of the previous
--  	 EC record for this PEIId. 
--
-- AJ - 25/Nov/2004
----------------------------------------------------------------------------- 	  	  	 
If (@StartTime Is Null)
 Select @StartTime = DateAdd(dd, -1, @EndTime)
