CREATE PROCEDURE dbo.spRS_WWWSearchReports
@Mask  	  	 VARCHAR(255), 
@User_Id 	 INT
AS
-- Need to figure out what the url is going to be
Declare @Count int
---------------------------
-- Local Variables
---------------------------
DECLARE @MySecurityGroup INT
--------------------------------------
-- What Security Group Do I Belong To
-- If None Assigned Then Admin
--------------------------------------
Select @MySecurityGroup = Group_Id from user_security where user_id = @User_Id
If @MySecurityGroup Is Null
 	 Select @MySecurityGroup = 1
CREATE TABLE #Temp_Table(
 	 NODE_TYPE 	 INT,
    CLASS_NAME  	 VARCHAR(255),
    NODE_NAME  	 VARCHAR(255),
 	 URL 	  	  	 VARCHAR(255)
)
---------------------------
-- Get Report Definitions
---------------------------
INSERT INTO #Temp_Table
SELECT 1, rt.Class_Name, Report_name, '../Viewer/RSFrontDoor.asp?ReportId=' + convert(varchar(20),rd.Report_Id) 
FROM   Report_Definitions rd
JOIN   Report_Types rt on rd.Report_Type_Id = rt.Report_Type_Id
WHERE  Class in (2, 3)
AND    (rd.Security_Group_Id >= @MySecurityGroup or rd.Security_Group_Id Is Null)
AND    Report_Name like '%' + @Mask + '%' 
---------------------------
-- Get Report Types
---------------------------
Insert Into #Temp_Table
Select 2, Class_Name, Description, '../Viewer/RSFrontDoor.asp?ReportTypeId=' + convert(varchar(20),rt.Report_Type_Id) 
From Report_Types rt
Where (rt.Security_Group_Id >= @MySecurityGroup or rt.Security_Group_Id Is Null)
And (Description like '%' + @Mask + '%' or Detail_Desc like '%' + @Mask + '%')
SELECT NODE_TYPE, convert(varchar(25), CLASS_NAME) 'CLASS_NAME', convert(varchar(30), NODE_NAME) 'NODE_NAME', URL FROM #Temp_Table
Where URL Is Not Null
ORDER BY NODE_TYPE, CLASS_NAME
DROP TABLE #Temp_Table
