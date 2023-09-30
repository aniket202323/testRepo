 /***************************************************************************************  
  
Creator:  Langdon Davis  
Date: 01/12/2006  
Purpose: This script identifies the report types and definitions that are using the   
   strRptLineStatusList parameter and brings back results sets of the values  
   currently assigned.  If the @GoAheadAndUpdate variable is set to 1, it then   
   goes on to update these values for the line status phrase changes being   
   implemented effective February 1, 2006 based on a mapping of...  
  
    The current Phrase_Values of...  
      Non-run - Global Included  
      Run - Global Included  
    ...translate to...  
      Rel Inc:Qual Unknown  
  
    The current Phrase_Values of...  
      Non-run - Global Excluded  
      Run - Global Excluded  
    ...translate to...  
      Rel Exc:Qual Unknown  
   
   It then brings back post-update results sets for reassurance/comparison.  
  
   Addtionally, the script then goes out and updates the local_PG_Line_Status for   
   the changes indicated by the above mapping with again, before and after results  
   sets for reassurance/comparison.  
  
   Last, but not least, the script goes and updates the Data_Type table to   
   insure the old line status data type has 'Old Line Status' as the Data_Type_  
   Desc, and the new line status data type has 'Line Status' with again, before   
   and after results sets for reassurance/comparison..  
  
***************************************************************************************/  
  
CREATE PROCEDURE dbo.spLocal_LineStatusUpdate  
AS  
-------------------------------------------------------------------------------  
-- Control settings  
-------------------------------------------------------------------------------  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON  
  
/***************************************************************************************  
         Report Parameters Section  
***************************************************************************************/  
  
declare @GoAheadAndUpdate int  
  
select @GoAheadAndUpdate = 1  
  
declare @ReportTypes table  
 (  
 ProcessPoint varchar(25),  
 RTP_Id   int,  
 ReportType   varchar(200),  
 Parameter  varchar(100),  
 Value    varchar(510),  
 xltPath   varchar(200)  
 )  
  
declare @ReportDefs table  
 (  
 ProcessPoint varchar(25),  
 RDP_Id   int,  
 ReportDef   varchar(200),  
 Parameter  varchar(100),  
 Value    varchar(510),  
 xltPath   varchar(200)  
 )  
  
insert @ReportTypes  
select    
 'ReportTypesBefore',  
 rtp.RTP_Id,  
 rt.[description] ReportType,  
 rp.rp_name Parameter,   
 convert(varchar(510),rtp.default_value) Value,  
 rt.template_path   
from report_types rt  
join report_type_parameters rtp on rt.report_type_id = rtp.report_type_id  
join report_parameters rp on rp.rp_id = rtp.rp_id  
where rp.rp_name = 'strRptLineStatusList'  
order by value, rp.rp_name, rt.description  
  
--select * from @ReportTypes order by rtp_id  
  
insert @ReportDefs  
select    
 'ReportDefsBefore',  
 rdp.RDP_Id,  
 rd.[report_name] ReportDef,  
 rp.rp_name Parameter,   
 convert(varchar,rdp.value) Value,  
 rt.template_path   
from report_types rt  
join report_type_parameters rtp on rt.report_type_id = rtp.report_type_id  
join report_parameters rp on rp.rp_id = rtp.rp_id  
join report_definitions rd on rt.report_type_id = rd.report_type_id  
join report_definition_parameters rdp on (rtp.rtp_id = rdp.rtp_id   
    and rd.report_id = rdp.report_id)  
where rp.rp_name = 'strRptLineStatusList'  
order by value, rp.rp_name, rt.description  
  
--select * from @ReportDefs order by rdp_id  
  
if @GoAheadAndUpdate = 1  
 BEGIN  
 update report_type_parameters set default_value = 'Rel Inc:Qual Unknown'  
 where rtp_id in ( select rtp_id from @ReportTypes  
       where value = 'Run - Global Included'   
       or value = 'Non-run - Global Included'  
       or value = 'Run - Global Included|Non-run - Global Included')  
  
 update report_type_parameters set default_value = 'Rel Exc:Qual Unknown'  
 where rtp_id in ( select rtp_id from @ReportTypes  
       where value = 'Run - Global Excluded'   
       or value = 'Non-run - Global Excluded'  
       or value = 'Run - Global Excluded|Non-run - Global Excluded')  
  
 update report_type_parameters set default_value = 'Rel Inc:Qual Unknown|Rel Exc:Qual Unknown'  
 where rtp_id in ( select rtp_id from @ReportTypes  
       where value like '%Included%Excluded%')  
  
 update report_definition_parameters set value = 'Rel Inc:Qual Unknown'  
 where rdp_id in ( select rdp_id from @ReportDefs  
       where value = 'Run - Global Included'   
       or value = 'Non-run - Global Included'  
       or value = 'Run - Global Included|Non-run - Global Included')  
  
 update report_definition_parameters set value = 'Rel Exc:Qual Unknown'  
 where rdp_id in ( select rdp_id from @ReportDefs  
       where value = 'Run - Global Excluded'   
       or value = 'Non-run - Global Excluded'  
       or value = 'Run - Global Excluded|Non-run - Global Excluded')  
  
 update report_definition_parameters set value = 'Rel Inc:Qual Unknown|Rel Exc:Qual Unknown'  
 where rdp_id in ( select rdp_id from @ReportDefs  
       where value like '%Included%Excluded%')  
  
--  insert @ReportTypes  
--  select    
--   'ReportTypesAfter',  
--   rtp.RTP_Id,  
--   rt.[description] ReportType,  
--   rp.rp_name Parameter,   
--   convert(varchar(510),rtp.default_value) Value,  
--   rt.template_path   
--  from report_types rt  
--  join report_type_parameters rtp on rt.report_type_id = rtp.report_type_id  
--  join report_parameters rp on rp.rp_id = rtp.rp_id  
--  where rp.rp_name = 'strRptLineStatusList'  
--  order by value, rp.rp_name, rt.description  
  
 --select * from @ReportTypes where ProcessPoint = 'ReportTypesAfter' order by rtp_id  
  
--  insert @ReportDefs  
--  select    
--   'ReportDefsAfter',  
--   rdp.RDP_Id,  
--   rd.[report_name] ReportDef,  
--   rp.rp_name Parameter,   
--   convert(varchar,rdp.value) Value,  
--   rt.template_path   
--  from report_types rt  
--  join report_type_parameters rtp on rt.report_type_id = rtp.report_type_id  
--  join report_parameters rp on rp.rp_id = rtp.rp_id  
--  join report_definitions rd on rt.report_type_id = rd.report_type_id  
--  join report_definition_parameters rdp on (rtp.rtp_id = rdp.rtp_id   
--      and rd.report_id = rdp.report_id)  
--  where rp.rp_name = 'strRptLineStatusList'  
--  order by value, rp.rp_name, rt.description  
  
 --select * from @ReportDefs where ProcessPoint = 'ReportDefsAfter' order by rdp_id  
  
 END  
  
/***************************************************************************************  
         local_PG_Line_Status Section  
***************************************************************************************/  
  
declare @Phrases table  
 (  
 PhraseId   int,  
 Value    varchar(510)  
 )  
  
declare @LineStatus table  
 (  
 ProcessPoint varchar(25),  
 RecordId   int,  
 LineStatusId int,  
 PUDesc    varchar(200),  
 Value    varchar(510)  
 )  
  
  
insert @Phrases  
SELECT  p.Phrase_Id,   
   p.Phrase_Value  
FROM   Phrase p   
INNER JOIN Data_Type dt ON dt.Data_Type_Id = p.Data_Type_Id AND dt.Data_Type_Desc LIKE '%line status%'  
  
--select 'Phrases',* from @Phrases  
  
Insert @LineStatus  
SELECT 'LineStatusBefore',  
   Local_PG_Line_Status.Status_Schedule_Id,   
   Local_PG_Line_Status.Line_Status_Id,   
   Prod_Units.PU_Desc,   
   Phrase.Phrase_Value  
FROM     Local_PG_Line_Status   
INNER JOIN Phrase ON Phrase.Phrase_Id = Local_PG_Line_Status.Line_Status_Id   
INNER JOIN Prod_Units ON Prod_Units.PU_Id = Local_PG_Line_Status.Unit_Id  
  
--select * from @LineStatus order by RecordId  
  
if @GoAheadAndUpdate = 1  
 BEGIN  
 update Local_PG_Line_Status set Line_Status_Id = ( select PhraseId from @Phrases   
                  where Value = 'Rel Inc:Qual Unknown')  
 where Line_Status_Id in ( select PhraseId from @Phrases  
          where value = 'Run - Global Included'   
          or value = 'Non-run - Global Included')  
  
 update Local_PG_Line_Status set Line_Status_Id = ( select PhraseId from @Phrases   
                  where Value = 'Rel Exc:Qual Unknown')  
 where Line_Status_Id in ( select PhraseId from @Phrases  
          where value = 'Run - Global Excluded'   
          or value = 'Non-run - Global Excluded')  
  
--  Insert @LineStatus  
--  SELECT 'LineStatusAfter',  
--     Local_PG_Line_Status.Status_Schedule_Id,   
--     Local_PG_Line_Status.Line_Status_Id,   
--     Prod_Units.PU_Desc,   
--     Phrase.Phrase_Value  
--  FROM     Local_PG_Line_Status   
--  INNER JOIN Phrase ON Phrase.Phrase_Id = Local_PG_Line_Status.Line_Status_Id   
--  INNER JOIN Prod_Units ON Prod_Units.PU_Id = Local_PG_Line_Status.Unit_Id  
  
 --select * from @LineStatus where ProcessPoint = 'LineStatusAfter' order by RecordId  
  
 END  
  
/***************************************************************************************  
               Data_Type Section  
***************************************************************************************/  
  
-- SELECT   'DataTypeBefore',   
--    dt.Data_Type_Id,   
--    dt.Data_Type_Desc,   
--    p.Phrase_Value  
-- FROM     Data_Type dt   
-- INNER JOIN Phrase p ON dt.Data_Type_Id = p.Data_Type_Id  
-- WHERE p.Phrase_Value = 'Non-run - Global Excluded'  
--  or p.Phrase_Value = 'Non-run - Global Included'  
--  or p.Phrase_Value = 'Run - Global Excluded'   
--  or p.Phrase_Value = 'Run - Global Included'  
--  or p.Phrase_Value = 'Rel Exc:Qual Cont Release'  
--  or p.Phrase_Value = 'Rel Exc:Qual Qualified'  
--  or p.Phrase_Value = 'Rel Exc:Qual Unknown'   
--  or p.Phrase_Value = 'Rel Exc:Qual Unqualified'  
--  or p.Phrase_Value = 'Rel Inc:Qual Cont Release'  
--  or p.Phrase_Value = 'Rel Inc:Qual Qualified'  
--  or p.Phrase_Value = 'Rel Inc:Qual Unknown'   
--  or p.Phrase_Value = 'Rel Inc:Qual Unqualified'  
  
if @GoAheadAndUpdate = 1  
 BEGIN  
 update Data_Type set Data_Type_Desc = 'Old Line Status'  
 where Data_Type_Id in ( select Data_Type_Id from Phrase  
         where Phrase_Value  = 'Non-run - Global Excluded'  
          or Phrase_Value   = 'Non-run - Global Included'  
         or Phrase_Value   = 'Run - Global Excluded'   
         or Phrase_Value   = 'Run - Global Included')  
  
 update Data_Type set Data_Type_Desc = 'Line Status'  
 where Data_Type_Id in ( select Data_Type_Id from Phrase  
         where Phrase_Value  = 'Rel Exc:Qual Cont Release'  
          or Phrase_Value   = 'Rel Exc:Qual Qualified'  
         or Phrase_Value   = 'Rel Exc:Qual Unknown'   
         or Phrase_Value   = 'Rel Exc:Qual Unqualified'  
         or Phrase_Value   = 'Rel Inc:Qual Cont Release'  
          or Phrase_Value   = 'Rel Inc:Qual Qualified'  
         or Phrase_Value   = 'Rel Inc:Qual Unknown'   
         or Phrase_Value   = 'Rel Inc:Qual Unqualified')  
  
--  SELECT   'DataTypeAfter',   
--     dt.Data_Type_Id,   
--     dt.Data_Type_Desc,   
--     p.Phrase_Value  
--  FROM     Data_Type dt   
--  INNER JOIN Phrase p ON dt.Data_Type_Id = p.Data_Type_Id  
--  WHERE p.Phrase_Value = 'Non-run - Global Excluded'  
--   or p.Phrase_Value = 'Non-run - Global Included'  
--   or p.Phrase_Value = 'Run - Global Excluded'   
--   or p.Phrase_Value = 'Run - Global Included'  
--   or p.Phrase_Value = 'Rel Exc:Qual Cont Release'  
--   or p.Phrase_Value = 'Rel Exc:Qual Qualified'  
--   or p.Phrase_Value = 'Rel Exc:Qual Unknown'   
--   or p.Phrase_Value = 'Rel Exc:Qual Unqualified'  
--   or p.Phrase_Value = 'Rel Inc:Qual Cont Release'  
--   or p.Phrase_Value = 'Rel Inc:Qual Qualified'  
--   or p.Phrase_Value = 'Rel Inc:Qual Unknown'   
--   or p.Phrase_Value = 'Rel Inc:Qual Unqualified'  
  
 END  
  
RETURN  
  
