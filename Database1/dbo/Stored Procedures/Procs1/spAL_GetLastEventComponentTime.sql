Create Procedure dbo.spAL_GetLastEventComponentTime
@PEIId int,
@LastTime datetime OUTPUT
AS
Select @LastTime = NULL
SELECT @LastTime = Max(ec.TimeStamp)
 	 From PrdExec_Inputs pei
 	 Join Events e on e.PU_Id = pei.PU_Id
 	 Join PrdExec_Input_Sources peis ON pei.PEI_Id = peis.PEI_Id
 	 Join Events e1 on peis.PU_Id = e1.PU_Id
 	 Join Event_Components ec ON e.Event_Id = ec.Event_Id And e1.Event_Id = ec.Source_Event_Id
 	 WHERE pei.PEI_Id = @PEIId
If @LastTime Is Null Select @LastTime = dbo.fnServer_CmnGetDate(getutcdate())
return(100)
