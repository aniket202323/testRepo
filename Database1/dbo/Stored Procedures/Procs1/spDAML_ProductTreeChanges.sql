CREATE Procedure dbo.spDAML_ProductTreeChanges
@Threshold DateTime
AS
DECLARE
   @Delimiter VARCHAR(1)
   Set @Delimiter = '.'
Select * from (
-- Check Product_Family_History Table for updates
--  Notes for Updates:
--         The old name must be fetched from the previous history record.
--         The new name must be fetched directly from the Product_Family table.
Select Operation 	 = pfh.DBTT_Id,
    NodeType 	  	 = 'F',
 	 TreeId 	  	  	 = pfh.Product_Family_Id,
    NewTreeName     = case when pfh.DBTT_Id<>3 then pfh.Product_Family_Desc
 	  	  	  	  	  	  	 else
                              (select pf.Product_Family_Desc from Product_Family pf
                                where pf.Product_Family_Id = pfh.Product_Family_Id)
                      end, 
 	 OldTreeName     = case when pfh.DBTT_Id<>3 then pfh.Product_Family_Desc
                           else (select top(1) pf.Product_Family_Desc from Product_Family_History pf 
                                  where pf.Product_Family_Id = pfh.Product_Family_Id and
 	  	  	  	  	  	  	  	  	     pf.Modified_On = 
 	  	  	  	  	  	  	  	  	  	 (select max(Modified_On) 
                                            from Product_Family_History ff
                                            where Modified_On < pfh.Modified_On
 	  	  	  	  	  	  	  	  	  	  	  	 and ff.Product_Family_Id = pfh.Product_Family_Id
                                        )
                                 )
 	  	  	  	  	    end,
    ParentKey 	  	 = 'Families.Products',
    ModifiedOn 	  	 = pfh.Modified_On
from Product_Family_History pfh 
where (pfh.Modified_On > @Threshold) 
UNION
-- Check Product_History Table for updates
--  Notes for Updates:
--         The old name must be fetched from the previous history record.
--         The new name must be fetched directly from the Products table.
Select Operation 	 = ph.DBTT_Id,
    NodeType 	  	 = 'P',
 	 TreeId 	  	  	 = ph.Prod_Id,
    NewTreeName     = case when ph.DBTT_Id<>3 then ph.Prod_Desc + ' (' + ph.Prod_Code + ')'
 	  	  	  	  	  	  	 else
                              (select p.Prod_Desc + ' (' + p.Prod_Code + ')' from Products p
                                where p.Prod_Id = ph.Prod_Id)
                      end, 
 	 OldTreeName     = case when ph.DBTT_Id<>3 then ph.Prod_Desc + ' (' + ph.Prod_Code + ')'
                           else (select top(1) p.Prod_Desc + ' (' + p.Prod_Code + ')' from Product_History p 
                                  where p.Prod_Id = ph.Prod_Id and
 	  	  	  	  	  	  	  	  	     p.Modified_On = 
 	  	  	  	  	  	  	  	  	  	 (select max(Modified_On) 
                                            from Product_History pp
                                            where Modified_On < ph.Modified_On
 	  	  	  	  	  	  	  	  	  	  	  	 and pp.Prod_Id = ph.Prod_Id
                                        )
                                 )
 	  	  	  	  	    end,
    ParentKey 	  	 =  'F' + Convert(varchar,ph.Product_Family_Id) + @Delimiter +  
 	  	  	  	  	    'Families.Products',
    ModifiedOn 	  	 = ph.Modified_On
from Product_History ph 
where (ph.Modified_On > @Threshold) 
UNION
-- Check Product_Properties_History Table for Updates
--  Notes for Updates:
--         The old name must be fetched from the previous history record.
--         The new name must be fetched directly from the Product_Properties table.
Select Operation 	 = pph.DBTT_Id,
    NodeType 	  	 = 'PP',
 	 TreeId 	  	  	 = pph.Prop_Id,
    NewTreeName     = case when pph.DBTT_Id<>3 then pph.Prop_Desc
 	  	  	  	  	  	  	 else
                              (select pp.Prop_Desc from Product_Properties pp
                                where pp.Prop_Id = pph.Prop_Id)
                      end, 
 	 OldTreeName     = case when pph.DBTT_Id<>3 then pph.Prop_Desc
                           else (select top(1) p.Prop_Desc from Product_Properties_History p 
                                  where p.Prop_Id = pph.Prop_Id and
 	  	  	  	  	  	  	  	  	     p.Modified_On = 
 	  	  	  	  	  	  	  	  	  	 (select max(Modified_On) 
                                            from Product_Properties_History ppp
                                            where Modified_On < pph.Modified_On
 	  	  	  	  	  	  	  	  	  	  	  	 and ppp.Prop_Id = pph.Prop_Id
                                        )
                                 )
 	  	  	  	  	    end,
    ParentKey 	  	 = 'Properties.Products',
    ModifiedOn 	  	 = pph.Modified_On
from Product_Properties_History pph 
where (pph.Modified_On > @Threshold)
UNION
-- Check Characteristic_History Table for updates
--  Notes for Updates:
--         The old name must be fetched from the previous history record.
--         The new name must be fetched directly from the Characteristics table.
Select Operation 	 = ch.DBTT_Id,
    NodeType 	  	 = 'C',
 	 TreeId 	  	  	 = ch.Char_Id,
    NewTreeName     = case when ch.DBTT_Id<>3 then ch.Char_Desc
 	  	  	  	  	  	  	 else
                              (select c.Char_Desc from Characteristics c
                                where c.Char_Id = ch.Char_Id)
                      end, 
 	 OldTreeName     = case when ch.DBTT_Id<>3 then ch.Char_Desc
                           else (select top(1) c.Char_Desc from Characteristic_History c 
                                  where c.Char_Id = ch.Char_Id and
 	  	  	  	  	  	  	  	  	     c.Modified_On = 
 	  	  	  	  	  	  	  	  	  	 (select max(Modified_On) 
                                            from Characteristic_History cc
                                            where Modified_On < ch.Modified_On
 	  	  	  	  	  	  	  	  	  	  	  	 and cc.Char_Id = ch.Char_Id
                                        )
                                 )
 	  	  	  	  	    end,
    ParentKey 	  	 = 'Characteristics' + @Delimiter +
 	  	  	  	  	   'PP' + Convert(varchar,ch.Prop_Id) + @Delimiter +
 	  	  	  	  	   'Properties.Products',
    ModifiedOn 	  	 = ch.Modified_On
from Characteristic_History ch 
where (ch.Modified_On > @Threshold)
UNION
-- Check Specification_History Table for updates
--  Notes for Updates:
--         The old name must be fetched from the previous history record.
--         The new name must be fetched directly from the Characteristics table.
Select Operation 	 = sh.DBTT_Id,
    NodeType 	  	 = 'S',
 	 TreeId 	  	  	 = sh.Spec_Id,
    NewTreeName     = case when sh.DBTT_Id<>3 then sh.Spec_Desc
 	  	  	  	  	  	  	 else
                              (select s.Spec_Desc from Specifications s
                                where s.Spec_Id = sh.Spec_Id)
                      end, 
 	 OldTreeName     = case when sh.DBTT_Id<>3 then sh.Spec_Desc
                           else (select top(1) s.Spec_Desc from Specification_History s 
                                  where s.Spec_Id = sh.Spec_Id and
 	  	  	  	  	  	  	  	  	     s.Modified_On = 
 	  	  	  	  	  	  	  	  	  	 (select max(Modified_On) 
                                            from Specification_History ss
                                            where Modified_On < sh.Modified_On
 	  	  	  	  	  	  	  	  	  	  	  	 and ss.Spec_Id = sh.Spec_Id
                                        )
                                 )
 	  	  	  	  	    end,
    ParentKey 	  	 = 'Specifications' + @Delimiter + 
                      'PP' + Convert(varchar,sh.Prop_Id) + @Delimiter + 
                      'Properties.Products',
    ModifiedOn 	  	 = sh.Modified_On
from Specification_History sh 
where (sh.Modified_On > @Threshold)
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
