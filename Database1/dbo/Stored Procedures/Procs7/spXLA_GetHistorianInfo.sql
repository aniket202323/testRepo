CREATE PROCEDURE dbo.spXLA_GetHistorianInfo 
 	 @PHNName varchar(20) = Null
AS
  Create Table #HistorianPW(Hist_Id Int,  Hist_Password  VarChar(255))
  Execute spCmn_GetHistorianPWData2 'EncrYptoR'
If @PHNName is NULL 
  BEGIN
    SELECT PHN_Id = h.Hist_Id, PHN_Name = COALESCE(Hist_Servername,''), PHN_Username = COALESCE(Hist_Username,''), PHN_Password = COALESCE(hp.Hist_Password,''), PHN_Default = COALESCE(Hist_Default,''), PHN_OS = Hist_OS_Id, h.Hist_Type_Id, Hist_Type_DllName = COALESCE(Hist_Type_DllName, '')
      FROM historians h
 	   Join #HistorianPW hp on hp.Hist_Id = h.Hist_Id
      JOIN HISTORIAN_TYPES t on t.Hist_Type_Id = h.Hist_Type_Id
    END
Else
  BEGIN
    SELECT PHN_Id = h.Hist_Id, PHN_Name = COALESCE(Hist_Servername,''), PHN_Username = COALESCE(Hist_Username,''), PHN_Password = COALESCE(hp.Hist_Password,''), PHN_Default = COALESCE(Hist_Default,''), PHN_OS = Hist_OS_Id, h.Hist_Type_Id, Hist_Type_DllName = COALESCE(Hist_Type_DllName, '')
      FROM historians h
 	   Join #HistorianPW hp on hp.Hist_Id = h.Hist_Id
      JOIN HISTORIAN_TYPES t on t.Hist_Type_Id = h.Hist_Type_Id
     WHERE Hist_Servername = @PHNName
  END
--EndIf
Drop table #HistorianPW
