Create Procedure dbo.spEMDT_GetFaults
@PU int,
@User_Id int
 AS 
select TEFault_Value as value, TEFault_Name as name 
  from timed_event_fault
  where Source_PU_Id = @PU
