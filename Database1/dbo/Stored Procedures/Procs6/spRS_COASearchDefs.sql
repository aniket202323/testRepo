Create Procedure dbo.spRS_COASearchDefs 
@SearchString varchar(50),
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spRS_COASearchDefs',
             @SearchString + ','  + 
             Convert(varchar(10),@User_Id), getdate())
SELECT @Insert_Id = Scope_Identity()
Declare @DescSearch varchar(50)
Select @DescSearch = @SearchString
If @DescSearch = ''
  Select @DescSearch = '%%'
Else
  Select @DescSearch = '%' + @DescSearch + '%'
--WRD_Id Column # (Total Columns - 1) for ListView
Select 7 as Column_Number
Select d.WRD_Desc as 'Description', r.Description as 'Report Type', t.WRT_Desc as 'Trigger Type', 
       a.WAT_Desc as 'Application Type', c.WARC_Desc as 'Reject Code',
      'Hold For Review' = CASE 
        WHEN d.Hold_For_Review = 1 THEN 'True'
        ELSE 'False'
      END,
      'Active' = CASE 
        WHEN d.Is_Active = 1 THEN 'True'
        ELSE 'False'
      END,
      d.WRD_Id as 'Id',
      'Reserved' = CASE
        WHEN d.WRD_Id <= 50 THEN 'True'
        ELSE 'False'
      END
From Web_Report_Definitions d
Left Outer Join Report_Types r on r.Report_Type_Id = d.Report_Type_Id
Left Outer Join Web_App_Types a on a.WAT_Id = d.WAT_Id
Left Outer Join Web_App_Reject_Codes c on c.WARC_Id = d.WARC_Id
Join Web_Report_Triggers t on t.WRT_Id = d.WRT_Id
Where d.WRD_Desc like @DescSearch
And d.WRD_Id <> 50
Order By d.WRD_Desc
UPDATE  Audit_Trail SET EndTime = getdate(),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
