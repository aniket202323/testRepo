CREATE PROCEDURE [dbo].[spBF_APIMyMachines_GetPreviousSelection] 
 	 @UserId Int
AS 
CREATE TABLE #AvailableUnitslist  (PU_Id Int , PU_Desc nVarChar(max), ET_Id Int , ET_Desc nvarchar(1000))
CREATE TABLE #LastPreferenceUnitslist   (PU_Id Int , ET_Id Int, Unit_PrefId int)
CREATE TABLE #nONExistingPreferences   (PU_Id Int , ET_Id Int,Unit_PrefId int)
--Get all the units user has acess to 
IF EXISTS (SELECT 1 FROM User_Security WITH(NOLOCK) WHERE User_Id = @UserId  AND Group_Id =1 and Access_Level = 4)
Begin
 	 ;WITH S AS( SELECT Distinct  de.Dept_Id, de.Dept_Desc ,pu.Non_Productive_Reason_Tree,pu.Non_Productive_Category,pl.PL_Id, pl.PL_Desc,pu.PU_Id, pu.PU_Desc, ec.ET_Id,et.ET_Desc,4 Access_Level From EVENT_Configuration ec   LEFT JOIN Event_Types et WITH(NOLOCK) on ec.ET_Id = et.ET_Id JOIN Prod_Units_Base pu  WITH(NOLOCK) on pu.PU_ID = ec.PU_ID JOIN Prod_Lines_Base pl WITH(NOLOCK) on pl.PL_Id = pu.PL_Id JOIN Departments_Base de WITH(NOLOCK) on de.Dept_Id = pl.Dept_Id WHERE pu.Master_Unit IS NULL),S1 as (SELECT T.Dept_Id, T.Dept_Desc ,T.PL_Id, T.PL_Desc,T.PU_Id, T.PU_Desc, T.ET_Id,T.ET_Desc,T.Access_Level FROM S T WHERE ET_Id IS NOT NULL),S2 as (SELECT T.Dept_Id, T.Dept_Desc ,T.PL_Id, T.PL_Desc,T.PU_Id, T.PU_Desc, T.ET_Id,T.ET_Desc,T.Access_Level FROM S T JOIN Sheet_Display_Options SDO ON T.PU_Id = SDO.Value AND sdo.Display_Option_Id = 446 JOIN Sheets s ON s.Sheet_Id = sdo.Sheet_Id JOIN Sheet_type st WITH(NOLOCK) ON s.Sheet_Type = st.Sheet_Type_Id AND st.ET_Id is Not null WHERE T.ET_ID IS NOT NULL and   Not EXISTS (SELECT 1 FROM S1 WHERE PU_Id = sdo.Value AND  ET_Id = st.ET_Id)),S3 as (SELECT Distinct  T.Dept_Id, T.Dept_Desc ,T.PL_Id, T.PL_Desc,T.PU_Id, T.PU_Desc, NULL ET_Id,NULL ET_Desc,T.Access_Level From S T JOIN Sheets S ON S.PL_Id= T.PL_Id AND  S.Sheet_Type=27 and S.Is_Active = 1 WHERE  T.Non_Productive_Category = 7 AND T.Non_Productive_Reason_Tree IS NOT NULL AND Not EXISTS (SELECT 1 FROM S1 WHERE PU_Id = T.PU_Id))
 	 INSERT INTO #AvailableUnitslist (PU_Id, PU_Desc, ET_Id,ET_Desc)
 	 Select PU_Id,PU_Desc,ET_Id,ET_Desc from S1
 	 union
 	 select PU_Id,PU_Desc,ET_Id,ET_Desc from s3
 	 union 
 	 select PU_Id,PU_Desc,ET_Id,ET_Desc from s2
End
Else
Begin
 	 INSERT INTO #AvailableUnitslist (PU_Id, PU_Desc, ET_Id,ET_Desc)
 	 SELECT PU_Id, PU_Desc, ET_Id,ET_Desc FROM dbo.fnBF_ApiFindAvailableUnitsAndEventTypes(@UserId)
End
--Retreive the preferences 
INSERT INTO #LastPreferenceUnitslist (PU_Id,ET_Id ,Unit_PrefId)
SELECT PU_Id,ET_Id,Unit_PrefId FROM dbo.User_UnitPreferences WITH(NOLOCK) WHERE User_Id = @UserId AND Profile_Id = -1
IF NOT EXISTS (SELECT 1 FROM #LastPreferenceUnitslist)
  	  BEGIN
  	    	  --return error
  	    	  SELECT ErrorCode = 'NoPreviousSelectionsExists'
  	    	  RETURN
  	  END
--compare whether all the previous preference units are in available unit list w.r.t event types
INSERT INTO #nONExistingPreferences (PU_Id,ET_Id,Unit_PrefId)
SELECT pul.pu_id,pul.ET_Id,pul.Unit_PrefId FROM #LastPreferenceUnitslist pul  
LEFT JOIN #AvailableUnitslist aul ON (pul.PU_Id <> aul.PU_Id)-- AND pul.ET_Id = aul.ET_Id)
WHERE aul.PU_Id IS NULL AND aul.ET_Id IS NULL
--Query previous preferences and return them 
SELECT 
d.Dept_Id,
d.Dept_Desc,
pl.PL_Id,
pl.PL_Desc,
ec.PU_Id, 
pu.PU_Desc, 
ec.ET_Id, 
et.ET_Desc
FROM dbo.Prod_Units_Base pu  
inner join User_UnitPreferences ec  on ec.Pu_Id=pu.PU_Id
inner join Event_Types et  on et.ET_Id=ec.ET_Id
Join dbo.Prod_Lines_Base pl  on pu.PL_Id = pl.PL_Id
join dbo.Departments_Base d  on pl.Dept_Id = d.Dept_Id
 WHERE ec.User_Id = @UserId AND ec.Profile_Id = -1 AND ec.Unit_PrefId Not in (Select Unit_PrefId from #nONExistingPreferences)
