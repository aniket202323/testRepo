CREATE PROCEDURE dbo.spEM_GetAvailPHNs
  @NumberOfHistorians int
  AS
  If (Select Count(Distinct Hist_Type_Id) From Historians WHERE Hist_Type_Id Not In (1, 2, 7, 100)) >= @NumberOfHistorians
    Begin
      SELECT 0 as 'Exit'
      SELECT Hist_Type_Id, Hist_Type_Desc 
        FROM Historian_Types 
        WHERE Hist_Type_Id In (1, 2, 7, 100)
        OR Hist_Type_Id In (Select Distinct Hist_Type_Id From Historians WHERE Hist_Type_Id Not In (1, 2, 7, 100))
        ORDER BY Hist_Type_Desc
    End
  Else
    SELECT 1 as 'Exit'
