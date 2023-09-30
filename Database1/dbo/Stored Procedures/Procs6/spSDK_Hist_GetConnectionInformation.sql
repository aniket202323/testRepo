Create Procedure dbo.spSDK_Hist_GetConnectionInformation
  @HistId INT = NULL,
  @AliasName varchar(50) = NULL
AS
Declare @FoundHistId Int
If @AliasName Is Not Null
  Begin
    Select @FoundHistId = Hist_Id
    From Historians
    Where Alias = @AliasName
    If @FoundHistId Is Not Null
      Begin
        If (@HistId Is Not Null) and (@HistId <> @FoundHistId)
          Raiserror('SP: Conflicting Values For Historian Id And Historian Alias', 16, 1)
      End
    Else
      Raiserror('SP: Invalid Alias', 16, 1)
  END
Else
  Begin
    Set @FoundHistId = @HistId
    Print 'PlantApps:ISI:No Alias Found, Using @HistId'
  End
print @FoundHistId
--Get the decrypted login information
Create Table #HistorianPW(Hist_Id Int,  Hist_Password  VarChar(255))
Execute spCmn_GetHistorianPWData2 'EncrYptoR'
SELECT h.Hist_Id, h.Alias, Hist_Servername HistServerName, Hist_Username UserName, hp.Hist_Password 'Password',
       Hist_OS_Id OSId, h.Is_Remote IsRemote, h.Hist_Default IsDefault, Hist_Type_DLLName DLLName,
       RDSServerName = Case h.Is_Remote When 1 Then h.Hist_Servername Else cs.Node_Name End
FROM Historians h
Join #HistorianPW hp on hp.Hist_Id = h.Hist_Id
Join Historian_Types t on t.Hist_Type_Id = h.Hist_Type_Id
Join cxs_Service cs On cs.Service_Id = 21 
Where (h.Hist_Id = @FoundHistId Or @FoundHistId IS Null)
--And (h.Alias = @AliasName Or @AliasName IS Null)
And h.Is_Active = 1
Select Hist_Id, Hist_Option_Id, Value
From Historian_Option_Data d
Where (d.Hist_Id = @FoundHistId)
Drop table #HistorianPW
