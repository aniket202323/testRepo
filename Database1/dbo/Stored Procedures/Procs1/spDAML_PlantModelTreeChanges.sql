CREATE Procedure dbo.spDAML_PlantModelTreeChanges 
   @Threshold DATETIME
AS
DECLARE
   @Delimiter VARCHAR(1)
   Set @Delimiter = '.'
/*  -- set up the UDP 
insert into table_fields (ed_field_type_id, Table_field_desc)  values(2,'NOSOAVAR')
-- set var_id 1 to be NOSOA 
insert into table_fields_values (keyid, table_field_id, tableid, value) 
  select 1, -- the var_id
    table_field_id, 20, 1 
    from table_fields where table_field_desc = 'NOSOAVAR'
*/
  DECLARE @TableFieldId int
  DECLARE @Vars TABLE (Var_Id int, Var_Desc varchar(50), PUG_Id int, PVar_Id int)
 	 DECLARE @Groups TABLE (Pug_Id int,PU_Id Int,PUG_Desc VarChar(50))
  IF (EXISTS(SELECT 1 from Variable_History vh where (vh.Modified_On > @Threshold)) or
      EXISTS(SELECT 1 from PU_Group_History gh where (gh.Modified_On > @Threshold)))
  BEGIN 
    DECLARE @VarsToSkip TABLE (Var_Id int)
    -- Fliter Out Department   (17)
    SELECT @TableFieldId = NULL
    SELECT @TableFieldId = Table_Field_Id  FROM table_fields where table_field_desc = 'NOSOAVAR' AND tableid = 17
    INSERT INTO @VarsToSkip(Var_Id)
      SELECT v.Var_Id
        From Variables v
        JOIN Prod_Units pu On pu.PU_Id = v.PU_Id
        JOIN Prod_Lines pl On pl.Pl_Id = pu.Pl_Id
        JOIN Table_fields_values tfv on tfv.Table_Field_Id = @TableFieldId AND tfv.tableid = 17 and tfv.Keyid = pl.Dept_Id 
        Where v.PU_Id > 0
    -- Fliter Out Line (18)
    SELECT @TableFieldId = NULL
    SELECT @TableFieldId = Table_Field_Id  FROM table_fields where table_field_desc = 'NOSOAVAR' AND tableid = 18
    INSERT INTO @VarsToSkip(Var_Id)
      SELECT v.Var_Id
        From Variables v
        JOIN Prod_Units pu On pu.PU_Id = v.PU_Id
        JOIN Prod_Lines pl On pl.Pl_Id = pu.Pl_Id
        JOIN Table_fields_values tfv on tfv.Table_Field_Id = @TableFieldId AND tfv.tableid = 18 and tfv.Keyid = pl.PL_Id 
        Where v.PU_Id > 0
    -- Fliter Out Unit (43)
    SELECT @TableFieldId = NULL
    SELECT @TableFieldId = Table_Field_Id  FROM table_fields where table_field_desc = 'NOSOAVAR' AND tableid = 43
    INSERT INTO @VarsToSkip(Var_Id)
      SELECT v.Var_Id
        From Variables v
        JOIN Prod_Units pu On pu.PU_Id = v.PU_Id
        JOIN Table_fields_values tfv on tfv.Table_Field_Id = @TableFieldId AND tfv.tableid = 43 and tfv.Keyid = pu.PU_Id 
        Where v.PU_Id > 0
    -- Fliter Out Group (19)
    SELECT @TableFieldId = NULL
    SELECT @TableFieldId = Table_Field_Id  FROM table_fields where table_field_desc = 'NOSOAVAR' AND tableid = 19
    INSERT INTO @VarsToSkip(Var_Id)
      SELECT v.Var_Id
        From Variables v
        JOIN Table_fields_values tfv3 on tfv3.Table_Field_Id = @TableFieldId AND tfv3.tableid = 19 and tfv3.Keyid = v.PUG_Id
        Where v.PU_Id > 0
    -- Fliter Out Variable  (20)
    SELECT @TableFieldId = NULL
    SELECT @TableFieldId = Table_Field_Id  FROM table_fields where table_field_desc = 'NOSOAVAR' AND tableid = 20
    INSERT INTO @VarsToSkip(Var_Id)
      SELECT v.Var_Id
        From Variables v
        JOIN Table_fields_values tfv3 on tfv3.Table_Field_Id = @TableFieldId AND tfv3.tableid = 20 and tfv3.Keyid = v.Var_Id
        Where v.PU_Id > 0
    --Get All Vars
    INSERT INTO @Vars (Var_Id , Var_Desc , PUG_Id , PVar_Id) 
      SELECT v.Var_Id , v.Var_Desc , v.PUG_Id , v.PVar_Id
        From Variables v
        Left Join @VarsToSkip vs on vs.Var_Id = v.Var_Id
        Where v.PU_Id > 0 and vs.Var_Id is null
    ----Remove Not needed
    --DELETE  @Vars
    -- 	 FROM @Vars v
    -- 	 JOIN @VarsToSkip vs on vs.Var_Id = v.Var_Id
    INSERT INTO @Groups(Pug_Id,PU_Id,PUG_Desc )
      SELECT DISTINCT a.PUG_Id,b.PU_Id,b.PUG_Desc
        FROM @Vars a
        Join PU_Groups b on b.PUG_Id = a.PUG_Id 
  END 
Select * from (
-- Check Department_History Table for Updates
--  Notes for Updates:
--         The old name must be fetched from the previous history record.
--         The new name must be fetched directly from the Departments table.
Select Operation 	 = dh.DBTT_Id,
    NodeType 	  	 = 'D',
 	 TreeId 	  	  	 = dh.Dept_Id,
    NewTreeName     = case when dh.DBTT_Id<>3 then dh.Dept_Desc
 	  	  	  	  	  	  	 else
                              (select d.Dept_Desc from Departments d
                                where d.Dept_Id = dh.Dept_Id)
                      end, 
    OldTreeName 	  	 = case when dh.DBTT_Id<>3 then dh.Dept_Desc
                           else (select top(1) d.Dept_Desc from Department_History d 
                                  where d.Dept_Id = dh.Dept_Id and
 	  	  	  	  	  	  	  	  	     d.Modified_On = 
 	  	  	  	  	  	  	  	  	  	 (select max(Modified_On) 
                                            from Department_History dd
                                            where Modified_On < dh.Modified_On
 	  	  	  	  	  	  	  	  	  	  	  	 and dd.Dept_Id = dh.Dept_Id
                                        )
                                 )
 	  	  	  	  	    end,
    ParentKey 	  	 = 'PlantModel',
    ModifiedOn 	  	 = dh.Modified_On
from Department_History dh 
where (dh.Modified_On > @Threshold) 
UNION
-- Check Prod_Line_History Table for Updates
--  Notes for Updates:
--         The old name must be fetched from the previous history record.
--         The new name must be fetched directly from the Prod_Lines table.
Select Operation 	 = plh.DBTT_Id,
    NodeType 	  	 = 'L',
 	 TreeId 	  	  	 = plh.PL_Id,
    NewTreeName     = case when plh.DBTT_Id<>3 then plh.PL_Desc
 	  	  	  	  	  	  	 else
                              (select pl.PL_Desc from Prod_Lines pl
                                where pl.PL_Id = plh.PL_Id)
                      end, 
    OldTreeName 	  	 = case when plh.DBTT_Id<>3 then plh.PL_Desc
                           else (select top(1) p.PL_Desc from Prod_Line_History p 
                                  where p.PL_Id = plh.PL_Id and
 	  	  	  	  	  	  	  	  	     p.Modified_On = 
 	  	  	  	  	  	  	  	  	  	 (select max(Modified_On) 
                                            from Prod_Line_History ll
                                            where Modified_On < plh.Modified_On
 	  	  	  	  	  	  	  	  	  	  	  	 and ll.PL_Id = plh.PL_Id
                                        )
                                 )
 	  	  	  	  	    end,
    ParentKey 	  	 =  'D' + (Convert(varchar,plh.Dept_Id)) + @Delimiter + 
                       'PlantModel',
    ModifiedOn 	  	 = plh.Modified_On
from Prod_Line_History plh 
where (plh.Modified_On > @Threshold) 
UNION
-- Check Prod_Unit_History table for updates
--  Notes for Updates:
--         The old name must be fetched from the previous history record.
--         The new name must be fetched directly from the Prod_Units table.
Select Operation 	 = puh.DBTT_Id,
    NodeType 	  	 = 'U',
 	 TreeId 	  	  	 = puh.PU_Id,
    NewTreeName 	  	 = case when puh.DBTT_Id<>3 then puh.PU_Desc
 	  	  	  	  	  	  	 else
                              (select pu.PU_Desc from Prod_Units pu 
                                where pu.PU_Id = puh.PU_Id)
                      end, 
    OldTreeName 	  	 = case when puh.DBTT_Id<>3 then puh.PU_Desc
                           else (select top(1) p.PU_Desc from Prod_Unit_History p 
                                  where p.PU_Id = puh.PU_Id and
 	  	  	  	  	  	  	  	  	     p.Modified_On = 
 	  	  	  	  	  	  	  	  	  	 (select max(Modified_On) 
                                            from Prod_Unit_History uu
                                            where Modified_On < puh.Modified_On
 	  	  	  	  	  	  	  	  	  	  	  	 and uu.PU_id = puh.PU_Id
                                        )
                                 )
 	  	  	  	  	    end,
    ParentKey 	  	  	 = 'L' + Convert(varchar,puh.PL_Id)  + @Delimiter + 
                          'D' + Convert(varchar,pl.Dept_id) + @Delimiter +
 	  	  	  	  	  	   'PlantModel',
    ModifiedOn 	  	 = puh.Modified_On
from Prod_Unit_History puh
join Prod_Lines pl on puh.PL_Id = pl.PL_Id
where (puh.Modified_On > @Threshold)
UNION
-- Check Variable_Group_History Table for updates
-- Notes for Updates:
--          The old name must be fetched from the previous history record.
Select Operation 	 = gh.DBTT_Id,
    NodeType 	  	 = 'G',
 	 TreeId 	  	  	 = gh.PUG_Id,
    NewTreeName     = gh.PUG_Desc, 
    OldTreeName 	  	 = case when gh.DBTT_Id<>3 then gh.PUG_Desc
                           else (select top(1) g.PUG_Desc from PU_Group_History g 
                                  where g.PUG_Id = gh.PUG_Id and
 	  	  	  	  	  	  	  	  	     g.Modified_On = 
 	  	  	  	  	  	  	  	  	  	 (select max(Modified_On) 
                                            from PU_Group_History gg
                                            where Modified_On < gh.Modified_On
 	  	  	  	  	  	  	  	  	  	  	  	 and gg.PUG_id = gh.PUG_Id
                                        )
                                 )
 	  	  	  	  	    end,
    ParentKey 	  	  	 = (Select top(1) 'U' + convert(varchar,pu1.PU_Id) + @Delimiter +
 	  	  	  	  	  	  	  	  	  	  'L' + convert(varchar,pl1.PL_Id) + @Delimiter +
                                         'D' + convert(varchar,pl1.Dept_Id) +  @Delimiter +  
                                         'PlantModel'
                                    from PU_Group_History gh1 
                                    join Prod_Units pu1 on pu1.PU_Id = gh1.PU_Id
                                    join Prod_Lines pl1 on pl1.PL_Id = pu1.PL_Id
                                    where gh1.PUG_Id = gh.PUG_Id and gh1.PUG_Id <>0),
    ModifiedOn 	  	 = gh.Modified_On
from PU_Group_History gh 
JOIN @Groups g on g.Pug_Id = gh.Pug_Id 
where (gh.Modified_On > @Threshold) 
UNION
-- Check Variable_History Table for parent variable updates
-- Notes for Deletions:
--          Variables do not get deleted, but the PU_Id will go to 0.
--          When the PU_Id is zero, the another history record must be used to
--          find the old PU_Id to form the key.
-- Notes for Updates:
--          The old name must be fetched from the previous history record.
-- Notes on the Tree Key:
--           If the PVar_Id is not null, then the parent variable is added to the key.
--           If the child variable has been deleted, a record with PU_ID<>0 must be used.
Select Operation 	 = case when vh.DBTT_Id = 2 then 2 
                           when vh.DBTT_Id = 4 then 4 
                           when vh.DBTT_Id = 3 and vh.PU_Id = 0 then 4 
 	  	  	  	  	  	    else 3
 	  	  	  	  	  	 end,
    NodeType 	  	 = 'V',
 	 TreeId 	  	  	 = vh.Var_Id,
    NewTreeName     = vh.Var_Desc, 
    OldTreeName 	  	 = case when vh.DBTT_Id<>3 then vh.Var_Desc
                           else (select top(1) p.Var_Desc from Variable_History p 
                                  where p.Var_Id = vh.Var_Id and
 	  	  	  	  	  	  	  	  	     p.Modified_On = 
 	  	  	  	  	  	  	  	  	  	 (select max(Modified_On) 
                                            from Variable_History vv
                                            where Modified_On < vh.Modified_On
 	  	  	  	  	  	  	  	  	  	  	  	 and vv.Var_id = vh.Var_Id
                                        )
                                 )
 	  	  	  	  	    end,
    ParentKey 	  	  	 = (Select top(1) case when (vh1.PVar_Id is null or vh1.PVar_Id = 0) then ''
                                              else ('V' + convert(varchar,vh1.PVar_Id) + @Delimiter)
 	  	  	  	  	  	  	  	  	  	  end +
 	  	  	  	  	  	  	  	  	  	 'G' + convert(varchar,vh1.PUG_Id) + @Delimiter + 
 	  	  	  	  	  	  	  	  	  	 'U' + convert(varchar,pug1.PU_Id) + @Delimiter + 
 	  	  	  	  	  	  	  	  	  	 'L' + convert(varchar,pu1.PL_Id) + @Delimiter + 
                                        'D' + convert(varchar,pl1.Dept_Id) + @Delimiter +
                                        'PlantModel' 	  	  	  	  	  	  	 
                                    from Variable_History vh1 
                                    join PU_Groups pug1 on vh1.PUG_Id = pug1.PUG_Id
                                    join Prod_Units pu1 on pu1.PU_Id = pug1.PU_Id
                                    join Prod_Lines pl1 on pl1.PL_Id = pu1.PL_Id
                                    where vh1.Var_Id = vh.Var_Id and vh1.PU_Id <>0),
    ModifiedOn 	  	 = vh.Modified_On
from Variable_History vh 
JOIN @vars v on v.Var_Id = vh.Var_Id 
where (vh.Modified_On > @Threshold) 
Union
-- Check Event_Configuration_History Table for updates
-- Notes for Updates:
--          Only addition and deletion records are returned
--          The PUId is returned in the TreeId, so that its events can be reloaded.
--          Only event types associated with a PRMsgs type are returned:  Production(1),  
--            Downtime(2), Waste(3), ProductChange(4), Genealogy(10), UserDefined(14)
Select Operation 	 = ech.DBTT_Id,
    NodeType 	  	 = 'E',
 	 TreeId 	  	  	 = ech.PU_Id,
    NewTreeName     = ech.EC_Desc,
    OldTreeName 	  	 = ech.EC_Desc,
    ParentKey 	  	 = (Select top(1) 'U' + convert(varchar,pu1.PU_Id) + @Delimiter +
 	  	  	  	  	  	  	  	  	  	  'L' + convert(varchar,pl1.PL_Id) + @Delimiter +
                                         'D' + convert(varchar,pl1.Dept_Id) +  @Delimiter +  
                                         'PlantModel'
                                    from Event_Configuration_History eh1 
                                    join Prod_Units pu1 on pu1.PU_Id = eh1.PU_Id
                                    join Prod_Lines pl1 on pl1.PL_Id = pu1.PL_Id
                                    where eh1.EC_Id = ech.EC_Id and eh1.EC_Id <>0),
    ModifiedOn 	  	 = ech.Modified_On
from Event_Configuration_History ech 
where (ech.Modified_On > @Threshold) and (ech.DBTT_Id <> 3) and (ech.ET_Id in (1,2,3,4,10,14))
Union
-- Check PrdExec_Path_Unit_History Table for updates
-- Notes for Updates:
--          Only addition and deletion records are returned
--          The PUId is returned in the TreeId, so that its events can be reloaded.
--          This is only used for ProductionPlanStartsEvents
Select Operation 	 = case when puh.DBTT_Id=3 and puh.Is_Schedule_Point = 0 then 4
                           when puh.DBTT_Id=3 and puh.Is_Schedule_Point = 1 then 2
                           else puh.DBTT_Id
 	  	  	  	  	   end,
    NodeType 	  	 = 'E',
 	 TreeId 	  	  	 = puh.PU_Id,
    NewTreeName     = 'Production Plan Start',
    OldTreeName 	  	 = 'Production Plan Start',
    ParentKey 	  	 = (Select top(1) 'U' + convert(varchar,pu1.PU_Id) + @Delimiter +
 	  	  	  	  	  	  	  	  	  	  'L' + convert(varchar,pl1.PL_Id) + @Delimiter +
                                         'D' + convert(varchar,pl1.Dept_Id) +  @Delimiter +  
                                         'PlantModel'
                                    from PrdExec_Path_Unit_History puh1 
                                    join Prod_Units pu1 on pu1.PU_Id = puh1.PU_Id
                                    join Prod_Lines pl1 on pl1.PL_Id = pu1.PL_Id
                                    where puh1.PEPU_Id = puh.PEPU_Id),
    ModifiedOn 	  	 = puh.Modified_On
from PrdExec_Path_Unit_History puh 
where (puh.Modified_On > @Threshold) and (puh.DBTT_Id = 3 OR puh.is_schedule_point = 1)
Union
-- Check PrdExec_Path_History Table for updates
-- Notes for Updates:
--          The old name must be fetched from the previous history record.
Select Operation 	 = pph.DBTT_Id,
    NodeType 	  	 = 'PE',
 	 TreeId 	  	  	 = pph.Path_Id,
    NewTreeName     = pph.Path_Desc,
    OldTreeName 	  	 = case when pph.DBTT_Id<>3 then pph.Path_Desc
                           else (select top(1) p.Path_Desc from PrdExec_Path_History p 
                                  where p.Path_Id = pph.Path_Id and
 	  	  	  	  	  	  	  	  	     p.Modified_On = 
 	  	  	  	  	  	  	  	  	  	 (select max(Modified_On) 
                                            from PrdExec_Path_History pp
                                            where Modified_On < pph.Modified_On
 	  	  	  	  	  	  	  	  	  	  	  	 and pp.Path_Id = pph.Path_Id
                                        )
                                 )
 	  	  	  	  	    end,
    ParentKey 	  	 = (Select top(1) 'Paths' + @Delimiter +
 	  	  	  	  	  	  	  	  	  'L' + convert(varchar,pl1.PL_Id) + @Delimiter +
                                     'D' + convert(varchar,pl1.Dept_Id) +  @Delimiter +  
                                     'PlantModel'
                                    from PrdExec_Path_History pph1 
                                    join Prod_Lines pl1 on pl1.PL_Id = pph1.PL_Id
                                    where pph1.Path_Id = pph.Path_Id and pph1.Path_Id <>0),
    ModifiedOn 	  	 = pph.Modified_On
from PrdExec_Path_History pph 
where (pph.Modified_On > @Threshold)
Union
-- Check PrdExec_Input_History Table for updates
-- Notes for Updates:
--          The old name must be fetched from the previous history record.
Select Operation 	 = pih.DBTT_Id,
    NodeType 	  	 = 'I',
 	 TreeId 	  	  	 = pih.PEI_Id,
    NewTreeName     = pih.Input_Name,
    OldTreeName 	  	 = case when pih.DBTT_Id<>3 then pih.Input_Name
                           else (select top(1) i.Input_Name from PrdExec_Input_History i 
                                  where i.PEI_Id = pih.PEI_Id and
 	  	  	  	  	  	  	  	  	     i.Modified_On = 
 	  	  	  	  	  	  	  	  	  	 (select max(Modified_On) 
                                            from PrdExec_Input_History ii
                                            where Modified_On < pih.Modified_On
 	  	  	  	  	  	  	  	  	  	  	  	 and ii.PEI_Id = pih.PEI_Id
                                        )
                                 )
 	  	  	  	  	    end,
    ParentKey 	  	  	 = (Select top(1) 'Inputs' + @Delimiter +
 	  	  	  	  	  	  	  	  	  	  'U' + convert(varchar,pu1.PU_Id) + @Delimiter +
 	  	  	  	  	  	  	  	  	  	  'L' + convert(varchar,pl1.PL_Id) + @Delimiter +
                                         'D' + convert(varchar,pl1.Dept_Id) +  @Delimiter +  
                                         'PlantModel'
                                    from PrdExec_Input_History pih1 
                                    join Prod_Units pu1 on pu1.PU_Id = pih1.PU_Id
                                    join Prod_Lines pl1 on pl1.PL_Id = pu1.PL_Id
                                    where pih1.PEI_Id = pih.PEI_Id),
    ModifiedOn 	  	 = pih.Modified_On
from PrdExec_Input_History pih 
where (pih.Modified_On > @Threshold)
) msg
-- Notes on where clause
--  If the key is null, then a node higher in the tree was deleted, so the record is not needed.
--  If the operation is Add or Delete, it needs to go through.
--  If the operation is Update, it only goes through if there was a name change.
where (msg.ParentKey is not null) 
  and (   (msg.Operation=2) 
       OR (msg.Operation=4) 
       OR ((msg.Operation=3) AND ((msg.NewTreeName<>msg.OldTreeName) AND (msg.NewTreeName is not null) AND (msg.OldTreeName is not null)))
       )
-- chronological order is important
order by ModifiedOn ASC
