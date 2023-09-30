CREATE PROCEDURE dbo.spServer_CmnGetEventComponent
@PU_Id int,
@TimeStamp datetime,
@Direction int,
@UseEquals int,
@Var_Id 	  Int,
@Component_Id int OUTPUT
 AS
--   Direction
--   --------------
--   1) Backward
--   2) Forward
--   3) Exact
Select @Component_Id = NULL
If (@Direction = 3)
  Begin
    If @Var_Id is null
 	     Select @Component_Id = a.Component_Id
 	       From Event_Components a
 	       Join Events b on (b.Event_Id = a.Source_Event_Id) And (b.PU_Id = @PU_Id) 
 	       Where (a.TimeStamp = @TimeStamp)
 	 Else
 	     Select @Component_Id = a.Component_Id
 	       From Event_Components a
 	       Join Events b on (b.Event_Id = a.Source_Event_Id) And (b.PU_Id = @PU_Id) 
 	       Join Variables_Base v on v.Var_Id = @Var_Id and v.PEi_Id = a.PEi_Id
 	       Where (a.TimeStamp = @TimeStamp)
  End
If (@Component_Id Is NULL)
  Select @Component_Id = 0
