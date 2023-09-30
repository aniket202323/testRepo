Create Procedure dbo.spEX_LineInformation
@PL_Id int,
@Sheet_Type int,
@Sheet_Id int
AS
If @Sheet_Type = 15 
  Begin
    If (Select Count(*) 
      From Prod_Units P
      Join Sheet_Unit U on U.PU_Id = P.PU_Id
      Where P.PL_Id = @PL_Id and
            P.Master_Unit Is Null and
            P.Timed_Event_Association > 0 and
            U.Sheet_Id = @Sheet_Id) = 0
      Begin
        Select PU_Id, PU_Desc 
          From Prod_Units 
          Where PL_Id = @PL_Id and
                Master_Unit Is Null and
                Timed_Event_Association > 0
      End
    Else
      Begin
        Select U.PU_Id, P.PU_Desc 
          From Prod_Units P
          Join Sheet_Unit U on U.PU_Id = P.PU_Id
          Where P.PL_Id = @PL_Id and
                P.Master_Unit Is Null and
                P.Timed_Event_Association > 0 and
                U.Sheet_Id = @Sheet_Id
      End
  End
return(100)
