Create Procedure dbo.spFF_ListLines     AS
  select pl_id, pl_desc 
    from prod_lines
    where pl_id > 0
    order by pl_desc
