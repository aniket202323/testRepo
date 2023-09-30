--    execute spEMAC_GetSPCTriggers 6,0,1
Create Procedure dbo.spEMAC_GetSPCTriggers
@AT_Id int,
@RunType int,
@User_Id int
AS
DECLARE @DisabledProduct Table(DisabledCount Int,ATSRDId Int)
INSERT INTO @DisabledProduct(DisabledCount,ATSRDId)
 	 SELECT COUNT(*),a.ATSRD_Id 
 	 FROM Alarm_SPC_Disabled_Products a
 	 JOIN Alarm_Template_SPC_Rule_Property_Data b ON a.ATSRD_Id = b.ATSRD_Id
 	 JOIN Alarm_Template_SPC_Rule_Data c on c.ATSRD_Id = b.ATSRD_Id and c.AT_Id = @AT_Id
 	 Group by a.ATSRD_Id
--Normal SPC template
If @RunType = 0
  Begin
 	  	 Select DisabledCount = coalesce(dp.DisabledCount,0),rd.ATSRD_Id,r.Alarm_SPC_Rule_Id, Alarm_SPC_Rule_Desc, p.Alarm_SPC_Rule_Property_Id, p.ED_Field_Type_Id, Field_Order, Alarm_SPC_Rule_Property_Desc,
 	  	   Default_Value, Value,Default_mValue, mValue, Coalesce(Firing_Priority, r.Alarm_SPC_Rule_Id + 30000) as Firing_Priority, f.Field_Type_Desc, ap.AP_Id, ap.AP_Desc,
 	  	   Uses_m_Value = case when r.Alarm_SPC_Rule_Id IN( 4,7,15,18,19) Then 0
 	  	  	  	  	  	  	   Else 1
 	  	  	  	  	  	  End
 	  	 from Alarm_SPC_Rules r
 	  	 join Alarm_SPC_Rule_Properties p on p.Alarm_SPC_Rule_Id =  r.Alarm_SPC_Rule_Id
 	  	 join ED_FieldTypes f on f.Ed_Field_Type_Id = p.ED_Field_Type_Id
 	  	 left outer join Alarm_Template_SPC_Rule_Data rd on rd.Alarm_SPC_Rule_Id = p.Alarm_SPC_Rule_Id and rd.AT_Id = @AT_Id
 	  	 left outer join Alarm_Template_SPC_Rule_Property_Data pd on pd.ATSRD_Id = rd.ATSRD_Id and pd.Alarm_SPC_Rule_Property_Id = p.Alarm_SPC_Rule_Property_Id
 	  	 left outer join Alarm_Priorities ap on ap.AP_Id = rd.AP_Id
 	  	 LEFT JOIN @DisabledProduct dp on dp.ATSRDId = pd.ATSRD_Id 
 	  	 order by Firing_Priority asc
  End
Else
  If @RunType = 1
 	 --SPC SubGroup template
 	   Begin
 	     Create Table #Rules (
 	       Alarm_SPC_Rule_Id  int, 
 	       SPC_Group_Variable_Type_Id int
 	     )
      Insert into #Rules (Alarm_SPC_Rule_Id, SPC_Group_Variable_Type_Id)
        Select r.Alarm_SPC_Rule_Id, sp.SPC_Group_Variable_Type_Id
          from Alarm_SPC_Rules r, SPC_Group_Variable_Types sp
  	  	  	 Select DisabledCount = coalesce(dp.DisabledCount,0),rd.ATSRD_Id,r.Alarm_SPC_Rule_Id, ar.Alarm_SPC_Rule_Desc, p.Alarm_SPC_Rule_Property_Id, p.ED_Field_Type_Id, Field_Order, Alarm_SPC_Rule_Property_Desc, sp.SPC_Group_Variable_Type_Id, sp.SPC_Group_Variable_Type_Desc,
  	  	  	   Default_Value, Value,Default_mValue, mValue, Coalesce(Firing_Priority, r.Alarm_SPC_Rule_Id + 30000) as Firing_Priority, f.Field_Type_Desc, ap.AP_Id, ap.AP_Desc,
  	  	  	   Uses_m_Value = case when r.Alarm_SPC_Rule_Id IN(4,7,15,18,19) Then 0
  	  	  	  	  	  	  	  	   Else 1
  	  	  	  	  	  	  	  End
        from #Rules r
  	  	  	 join Alarm_SPC_Rules ar on ar.Alarm_SPC_Rule_Id = r.Alarm_SPC_Rule_Id
  	  	  	 join Alarm_SPC_Rule_Properties p on p.Alarm_SPC_Rule_Id =  r.Alarm_SPC_Rule_Id
  	  	  	 join ED_FieldTypes f on f.Ed_Field_Type_Id = p.ED_Field_Type_Id
      join SPC_Group_Variable_Types sp on sp.SPC_Group_Variable_Type_Id = r.SPC_Group_Variable_Type_Id
  	  	  	 left outer join Alarm_Template_SPC_Rule_Data rd on rd.Alarm_SPC_Rule_Id = p.Alarm_SPC_Rule_Id and rd.AT_Id = @AT_Id and rd.SPC_Group_Variable_Type_Id = r.SPC_Group_Variable_Type_Id
  	  	  	 left outer join Alarm_Template_SPC_Rule_Property_Data pd on pd.ATSRD_Id = rd.ATSRD_Id and pd.Alarm_SPC_Rule_Property_Id = p.Alarm_SPC_Rule_Property_Id
  	  	  	 left outer join Alarm_Priorities ap on ap.AP_Id = rd.AP_Id
  	  	  	 LEFT JOIN @DisabledProduct dp on dp.ATSRDId = pd.ATSRD_Id 
 	  	  	 order by Firing_Priority, sp.SPC_Group_Variable_Type_Id asc
      Drop table #Rules
 	   End
