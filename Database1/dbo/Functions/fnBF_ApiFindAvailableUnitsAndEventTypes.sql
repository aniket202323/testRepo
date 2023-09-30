CREATE FUNCTION dbo.fnBF_ApiFindAvailableUnitsAndEventTypes(@UserId int) 
  	  RETURNS  @AvailableUnitslist Table (Dept_Id Int, Dept_Desc nvarchar(1000),PL_Id Int, PL_Desc nvarchar(1000),PU_Id Int ,
 	  PU_Desc nvarchar(1000), ET_Id Int , ET_Desc nvarchar(1000),Access_level int)
AS 
BEGIN
DECLARE @AvailableUnits Table (PU_Id Int , ET_Id Int , ET_Desc nvarchar(1000),Access_level int)
    	    IF Exists(SELECT 1 FROM User_Security WITH(NOLOCK) WHERE User_Id = @UserId  AND Group_Id =1 and Access_Level = 4) -- admin to admin
    	    BEGIN
    	        	    INSERT INTO @AvailableUnitslist(Dept_Id , Dept_Desc ,PL_Id , PL_Desc,PU_Id,PU_Desc,ET_Id,ET_Desc,Access_level)
    	        	        	    SELECT Distinct  de.Dept_Id, de.Dept_Desc ,
    	        	        	    pl.PL_Id, pl.PL_Desc,
    	        	        	    pu.PU_Id, pu.PU_Desc, ec.ET_Id,et.ET_Desc,4 From EVENT_Configuration ec WITH(NOLOCK) JOIN Event_Types et WITH(NOLOCK) on ec.ET_Id = et.ET_Id
    	        	        	    JOIN Prod_Units_Base pu  WITH(NOLOCK) on pu.PU_ID = ec.PU_ID 
    	        	        	    JOIN Prod_Lines_Base pl WITH(NOLOCK) on pl.PL_Id = pu.PL_Id 
    	        	        	    JOIN Departments_Base de WITH(NOLOCK) on de.Dept_Id = pl.Dept_Id WHERE pu.Master_Unit IS NULL 
  	   
   	   -- for time based sheets the mapping for Sheet vs Unit is in Sheet_Display_Options under Display_Option_Id = 446
   	      	   INSERT INTO @AvailableUnitslist(Dept_Id , Dept_Desc ,PL_Id , PL_Desc, PU_Id, PU_Desc, ET_Id, ET_Desc, Access_level)
   	      	   SELECT DISTINCT de.Dept_Id, de.Dept_Desc ,pl.PL_Id, pl.PL_Desc, pu.PU_Id, pu.PU_Desc, et.ET_Id, et.ET_Desc, 4
   	      	   FROM Sheet_Display_Options sdo WITH(NOLOCK)
   	      	      	    JOIN Sheets s WITH(NOLOCK) ON s.Sheet_Id = sdo.Sheet_Id
   	      	      	    JOIN Sheet_type st WITH(NOLOCK) ON s.Sheet_Type = st.Sheet_Type_Id AND st.ET_Id is Not null
    	      	      	    JOIN Event_Types et WITH(NOLOCK) ON st.ET_Id = et.ET_Id
   	      	      	    JOIN Prod_Units_Base pu  WITH(NOLOCK) ON pu.PU_ID = sdo.Value AND pu.Master_Unit IS NULL
    	        	        	    JOIN Prod_Lines_Base pl WITH(NOLOCK) ON pl.PL_Id = pu.PL_Id 
    	        	        	    JOIN Departments_Base de WITH(NOLOCK) ON de.Dept_Id = pl.Dept_Id 
   	      	   WHERE sdo.Display_Option_Id = 446  
   	      	   AND Not EXISTS (SELECT 1 FROM @AvailableUnitslist WHERE PU_Id = sdo.Value AND  ET_Id = st.ET_Id)
    	     
  	     -- Add units configured with NPT, in case that was not a part of previous selection
       INSERT INTO @AvailableUnitslist(Dept_Id , Dept_Desc ,PL_Id , PL_Desc, PU_Id, PU_Desc, ET_Id, ET_Desc, Access_level)
  	    	  SELECT Distinct  de.Dept_Id, de.Dept_Desc , pl.PL_Id, pl.PL_Desc, pu.PU_Id, pu.PU_Desc, null,null,4 
  	    	  FROM Sheets S WITH(NOLOCK) JOIN Prod_Units_Base pu  WITH(NOLOCK) ON S.PL_Id = PU.PL_Id AND S.Sheet_Type=27 and S.Is_Active = 1 AND PU.Non_Productive_Category = 7 AND PU.Non_Productive_Reason_Tree IS NOT NULL
  	    	  JOIN Prod_Lines_Base pl WITH(NOLOCK) on pl.PL_Id = pu.PL_Id 
  	    	  JOIN Departments_Base de WITH(NOLOCK) on de.Dept_Id = pl.Dept_Id  
  	    	  WHERE pu.Master_Unit IS NULL 
  	    	  AND Not EXISTS (SELECT 1 FROM @AvailableUnitslist WHERE PU_Id = pu.PU_Id)
  	    	  
  	    	  RETURN
    	    END
    	   --check for security at display level (only includes units associated with sheets that are active)
    	    INSERT INTO @AvailableUnits(PU_Id,ET_Id,ET_Desc,Access_level)
    	        	    SELECT distinct a.Master_Unit, st.ET_Id ,et.ET_Desc,c.Access_level
    	        	    FROM Sheets a WITH(NOLOCK)
    	        	    JOIN Sheet_type st WITH(NOLOCK) on a.Sheet_Type = st.Sheet_Type_Id AND a.Is_Active =1
    	        	    JOIN  User_Security c WITH(NOLOCK) on c.Group_Id = a.Group_Id AND c.User_Id = @UserId 
    	        	    LEFT OUTER JOIN Event_Types et on st.ET_Id = et.ET_Id
--check for display group level security (only includes units associated with sheets that are active)
    	    INSERT INTO @AvailableUnits(PU_Id,ET_Id,ET_Desc,Access_level)
    	        	    SELECT distinct a.Master_Unit, st.ET_Id ,et.ET_Desc,c.Access_Level
    	        	    FROM Sheets a WITH(NOLOCK)
    	        	    JOIN Sheet_type st WITH(NOLOCK) on a.Sheet_Type = st.Sheet_Type_Id AND a.Is_Active =1
    	        	    join Sheet_Groups sg WITH(NOLOCK) on a.Sheet_Group_Id = sg.Sheet_Group_Id
    	        	    JOIN  User_Security c WITH(NOLOCK) on c.Group_Id = sg.Group_Id AND c.User_Id = @UserId 
   	      	    LEFT OUTER JOIN Event_Types et WITH(NOLOCK) on st.ET_Id = et.ET_Id
    	        	    WHERE a.Group_Id Is Null and sg.Group_Id is  not null
    	        	    and  a.Master_Unit is  not null
    	    --no security at group or display level (only includes units associated with sheets that are active)
    	    INSERT INTO @AvailableUnits(PU_Id,ET_Id,ET_Desc,Access_level)
    	        	    SELECT distinct a.Master_Unit, st.ET_Id ,et.ET_Desc,3
    	        	    FROM Sheets a WITH(NOLOCK)
    	        	    JOIN Sheet_type st WITH(NOLOCK) on a.Sheet_Type = st.Sheet_Type_Id AND a.Is_Active =1
    	        	    join Sheet_Groups sg WITH(NOLOCK) on a.Sheet_Group_Id = sg.Sheet_Group_Id
   	      	    LEFT OUTER JOIN Event_Types et WITH(NOLOCK) on st.ET_Id = et.ET_Id
    	        	    WHERE a.Group_Id Is Null and sg.Group_Id is null
    	        	    --check for  security at display level for +views (only includes units associated with sheets that are active)
    	    INSERT INTO @AvailableUnits(PU_Id,ET_Id,ET_Desc,Access_level)
    	        	    SELECT distinct a.PU_Id ,st.ET_Id,et.ET_Desc,c.Access_level
    	        	    FROM Sheet_Unit  a WITH(NOLOCK)
    	        	    JOIN Sheets b WITH(NOLOCK) on b.Sheet_Id = a.Sheet_Id AND b.Is_Active =1
    	        	    JOIN Sheet_type st WITH(NOLOCK) on b.Sheet_Type = st.Sheet_Type_Id
    	        	    JOIN  User_Security c WITH(NOLOCK) on c.Group_Id = b.Group_Id AND c.User_Id = @UserId 
    	        	    LEFT OUTER JOIN Event_Types et WITH(NOLOCK) on st.ET_Id = et.ET_Id
    	        	    --security at display group level (only includes units associated with sheets that are active)
    	        	    INSERT INTO @AvailableUnits(PU_Id,ET_Id,ET_Desc,Access_level)
    	        	    SELECT  distinct a.PU_Id,st.ET_Id,et.ET_Desc,c.Access_Level
    	        	    FROM Sheet_Unit  a WITH(NOLOCK)
    	        	    JOIN Sheets b WITH(NOLOCK) on b.Sheet_Id = a.Sheet_Id  AND b.Is_Active =1
    	        	    join Sheet_Groups sg WITH(NOLOCK) on b.Sheet_Group_Id = sg.Sheet_Group_Id
    	        	    JOIN Sheet_type st WITH(NOLOCK) on b.Sheet_Type = st.Sheet_Type_Id
    	        	    JOIN  User_Security c WITH(NOLOCK) on c.Group_Id = sg.Group_Id AND c.User_Id = @UserId 
   	      	    LEFT OUTER JOIN Event_Types et on st.ET_Id = et.ET_Id
    	        	    WHERE b.Group_Id Is Null and sg.Group_Id is  not null
    	        	    --no security  (only includes units associated with sheets that are active)
    	    INSERT INTO @AvailableUnits(PU_Id,ET_Id,ET_Desc,Access_level)
    	        	    SELECT  distinct a.PU_Id,st.ET_Id,et.ET_Desc,3
    	        	    FROM Sheet_Unit  a WITH(NOLOCK)
    	        	    JOIN Sheets b WITH(NOLOCK) on b.Sheet_Id = a.Sheet_Id AND b.Is_Active =1 
    	        	    JOIN Sheet_type st WITH(NOLOCK) on b.Sheet_Type = st.Sheet_Type_Id
    	        	    join Sheet_Groups sg WITH(NOLOCK) on b.Sheet_Group_Id = sg.Sheet_Group_Id
   	      	    LEFT OUTER JOIN Event_Types et WITH(NOLOCK) on st.ET_Id = et.ET_Id
    	        	    WHERE b.Group_Id Is Null and  sg.Group_Id is null
    	    
   	    -- Getting all the active sheet Ids that @UserId have access to
   	     ;WITH S as 
   	      	   (   -- Display/Sheet level security
   	      	      	   SELECT Sheet_Id,Access_level FROM Sheets s  WITH(NOLOCK) JOIN  User_Security us WITH(NOLOCK) ON us.Group_Id = s.Group_Id AND us.user_id = @UserId  AND s.Is_Active =1
   	      	      	       WHERE s.Group_Id is Not null
   	      	      	      	   UNION
            -- Display Group/Sheet Group level security
   	      	      	   SELECT Sheet_Id,Access_level FROM Sheets s WITH(NOLOCK)
   	      	      	      	   JOIN Sheet_Groups sg  WITH(NOLOCK) ON sg.Sheet_Group_Id=s.Sheet_Group_Id  AND s.Is_Active =1
   	      	      	      	   JOIN  User_Security us WITH(NOLOCK) ON us.Group_Id = sg.Group_Id AND us.user_id = @UserId
   	      	      	      	   WHERE s.Group_Id is null AND sg.Group_Id is Not null AND s.Is_Active =1
   	      	      	      	   UNION
            --Display or Display group that is not assigned any security
   	      	      	   SELECT Sheet_Id ,3 Access_level
   	      	      	      	   FROM Sheets s   WITH(NOLOCK)
   	      	      	      	   JOIN Sheet_Groups sg  WITH(NOLOCK) ON sg.Sheet_Group_Id=s.Sheet_Group_Id  AND s.Is_Active =1
   	      	      	      	   WHERE s.Group_Id is null AND SG.Group_Id is null
   	   
   	      	   )
   	   -- for time based sheets the mapping for Sheet vs Unit is in Sheet_Display_Options under Display_Option_Id = 446
   	      	   INSERT INTO @AvailableUnits(PU_Id,ET_Id,ET_Desc,Access_level)
   	      	   SELECT DISTINCT sdo.Value as PU_Id , st.ET_Id ,et.ET_Desc,T.Access_Level
   	      	   FROM Sheet_Display_Options sdo WITH(NOLOCK)
   	      	      	    JOIN Sheets s  WITH(NOLOCK) ON s.Sheet_Id = sdo.Sheet_Id
   	      	      	    JOIN Sheet_type st WITH(NOLOCK) ON s.Sheet_Type = st.Sheet_Type_Id AND st.ET_Id is Not null
    	      	      	    JOIN Event_Types et WITH(NOLOCK) ON st.ET_Id = et.ET_Id
   	      	      	    JOIN S T ON T.Sheet_Id = sdo.Sheet_Id
   	      	   WHERE sdo.Display_Option_Id = 446 AND 
   	      	   Exists (SELECT 1 FROM S WHERE Sheet_Id = sdo.Sheet_Id)    	    
   	      	   AND Not EXISTS (SELECT 1 FROM @AvailableUnits WHERE PU_Id = sdo.Value
   	      	   AND  ET_Id = st.ET_Id
   	      	   AND ET_Desc = et.ET_Desc
   	      	   AND Access_level = T.Access_Level)
     -- Checking the security and selecting the NPT sheets and corresponding units
  	    -- Getting all the active sheet Ids that @UserId have access to
   	     ;WITH NPT_Sheets as 
   	      	   (   -- Display/Sheet level security
   	      	      	   SELECT Sheet_Id,Access_level, PL_Id FROM Sheets s WITH(NOLOCK)  JOIN  User_Security us WITH(NOLOCK) ON us.Group_Id = s.Group_Id AND us.user_id = @UserId  AND s.Is_Active =1
   	      	      	       WHERE s.Group_Id is Not null AND Sheet_Type = 27
   	      	      	      	   UNION
            -- Display Group/Sheet Group level security
   	      	      	   SELECT Sheet_Id,Access_level, PL_Id  FROM Sheets s WITH(NOLOCK)
   	      	      	      	   JOIN Sheet_Groups sg WITH(NOLOCK) ON sg.Sheet_Group_Id=s.Sheet_Group_Id  AND s.Is_Active =1
   	      	      	      	   JOIN  User_Security us WITH(NOLOCK) ON us.Group_Id = sg.Group_Id AND us.user_id = @UserId
   	      	      	      	   WHERE s.Group_Id is null AND sg.Group_Id is Not null AND s.Is_Active =1  AND s.Sheet_Type = 27
   	      	      	      	   UNION
            --Display or Display group that is not assigned any security
   	      	      	   SELECT Sheet_Id ,3 Access_level, PL_Id 
   	      	      	      	   FROM Sheets s  WITH(NOLOCK) 
   	      	      	      	   JOIN Sheet_Groups sg WITH(NOLOCK) ON sg.Sheet_Group_Id=s.Sheet_Group_Id  AND s.Is_Active =1
   	      	      	      	   WHERE s.Group_Id is null AND SG.Group_Id is null AND s.Sheet_Type = 27
   	   
   	      	   )
  	    	   INSERT INTO @AvailableUnits(PU_Id,Access_level)
   	      	   SELECT Distinct  pu.PU_Id, S.Access_Level 
  	    	   FROM NPT_Sheets S WITH(NOLOCK) JOIN Prod_Units_Base pu  WITH(NOLOCK) ON S.PL_Id = PU.PL_Id AND PU.Non_Productive_Category = 7 AND PU.Non_Productive_Reason_Tree IS NOT NULL
     -- inserting into the result Set    	    
    	    INSERT INTO @AvailableUnitslist (Dept_Id , Dept_Desc ,PL_Id , PL_Desc, PU_Id ,PU_Desc , ET_Id ,ET_Desc,Access_level) 
    	    SELECT DISTINCT de.Dept_Id, de.Dept_Desc ,
    	        	        	        	        	    pl.PL_Id, pl.PL_Desc,
    	        	        	        	        	    Au.PU_Id, pu.PU_Desc,ET_Id ,ET_Desc,Access_level FROM @AvailableUnits Au  
    	        	        	    JOIN Prod_Units_Base pu  WITH(NOLOCK) on au.PU_ID = pu.PU_ID 
    	        	        	    JOIN Prod_Lines_Base pl WITH(NOLOCK) on pu.PL_Id = pl.PL_Id 
    	        	        	    JOIN Departments_Base de WITH(NOLOCK) on pl.Dept_Id = de.Dept_Id 
    	    WHERE au.PU_Id is not null AND au.PU_Id > 0 AND pu.Master_Unit IS NULL  ORDER BY au.PU_Id
    	    
    	    RETURN
END
