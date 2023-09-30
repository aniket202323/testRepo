CREATE TABLE [dbo].[Variable_History] (
    [Variable_History_Id]          BIGINT                    IDENTITY (1, 1) NOT NULL,
    [Data_Type_Id]                 INT                       NULL,
    [DS_Id]                        INT                       NULL,
    [PU_Id]                        INT                       NULL,
    [PUG_Id]                       INT                       NULL,
    [Var_Desc]                     [dbo].[Varchar_Desc]      NULL,
    [Event_Type]                   TINYINT                   NULL,
    [Is_Conformance_Variable]      BIT                       NULL,
    [PUG_Order]                    INT                       NULL,
    [Rank]                         [dbo].[Smallint_Pct]      NULL,
    [SA_Id]                        TINYINT                   NULL,
    [Unit_Reject]                  BIT                       NULL,
    [Unit_Summarize]               BIT                       NULL,
    [Var_Reject]                   BIT                       NULL,
    [Calculation_Id]               INT                       NULL,
    [Comment_Id]                   INT                       NULL,
    [Comparison_Operator_Id]       INT                       NULL,
    [Comparison_Value]             VARCHAR (50)              NULL,
    [CPK_SubGroup_Size]            INT                       NULL,
    [DQ_Tag]                       VARCHAR (255)             NULL,
    [Eng_Units]                    [dbo].[Varchar_Eng_Units] NULL,
    [Esignature_Level]             INT                       NULL,
    [Event_Dimension]              TINYINT                   NULL,
    [Event_Subtype_Id]             INT                       NULL,
    [Extended_Info]                VARCHAR (255)             NULL,
    [External_Link]                [dbo].[Varchar_Ext_Link]  NULL,
    [Group_Id]                     INT                       NULL,
    [Input_Tag]                    VARCHAR (255)             NULL,
    [Input_Tag2]                   VARCHAR (255)             NULL,
    [LEL_Tag]                      VARCHAR (255)             NULL,
    [LRL_Tag]                      VARCHAR (255)             NULL,
    [LUL_Tag]                      VARCHAR (255)             NULL,
    [LWL_Tag]                      VARCHAR (255)             NULL,
    [Max_RPM]                      FLOAT (53)                NULL,
    [Output_DS_Id]                 INT                       NULL,
    [Output_Tag]                   VARCHAR (255)             NULL,
    [PEI_Id]                       INT                       NULL,
    [ProdCalc_Type]                TINYINT                   NULL,
    [PVar_Id]                      INT                       NULL,
    [ReadLagTime]                  INT                       NULL,
    [Reload_Flag]                  TINYINT                   NULL,
    [Repeat_Backtime]              INT                       NULL,
    [Repeating]                    TINYINT                   NULL,
    [Reset_Value]                  FLOAT (53)                NULL,
    [Retention_Limit]              INT                       NULL,
    [Sampling_Interval]            [dbo].[Smallint_Offset]   NULL,
    [Sampling_Offset]              [dbo].[Smallint_Offset]   NULL,
    [Sampling_Reference_Var_Id]    INT                       NULL,
    [Sampling_Type]                TINYINT                   NULL,
    [Sampling_Window]              INT                       NULL,
    [SPC_Calculation_Type_Id]      INT                       NULL,
    [SPC_Group_Variable_Type_Id]   INT                       NULL,
    [Spec_Id]                      INT                       NULL,
    [String_Specification_Setting] TINYINT                   NULL,
    [System]                       TINYINT                   NULL,
    [Tag]                          VARCHAR (50)              NULL,
    [Target_Tag]                   VARCHAR (255)             NULL,
    [Test_Name]                    VARCHAR (50)              NULL,
    [UEL_Tag]                      VARCHAR (255)             NULL,
    [URL_Tag]                      VARCHAR (255)             NULL,
    [User_Defined1]                VARCHAR (255)             NULL,
    [User_Defined2]                VARCHAR (255)             NULL,
    [User_Defined3]                VARCHAR (255)             NULL,
    [UUL_Tag]                      VARCHAR (255)             NULL,
    [UWL_Tag]                      VARCHAR (255)             NULL,
    [Var_Precision]                [dbo].[Tinyint_Precision] NULL,
    [Write_Group_DS_Id]            INT                       NULL,
    [ArrayStatOnly]                TINYINT                   NULL,
    [Debug]                        BIT                       NULL,
    [Extended_Test_Freq]           INT                       NULL,
    [Force_Sign_Entry]             TINYINT                   NULL,
    [Is_Active]                    BIT                       NULL,
    [Perform_Event_Lookup]         TINYINT                   NULL,
    [ShouldArchive]                TINYINT                   NULL,
    [TF_Reset]                     TINYINT                   NULL,
    [Tot_Factor]                   REAL                      NULL,
    [Var_Id]                       INT                       NULL,
    [Modified_On]                  DATETIME                  NULL,
    [DBTT_Id]                      TINYINT                   NULL,
    [Column_Updated_BitMask]       VARCHAR (15)              NULL,
    [Ignore_Event_Status]          TINYINT                   NULL,
    CONSTRAINT [Variable_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Variable_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [VariableHistory_IX_VarIdModifiedOn]
    ON [dbo].[Variable_History]([Var_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Variable_History_UpdDel]
 ON  [dbo].[Variable_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) --DataPurge
BEGIN
 	 DELETE Variable_History
 	 FROM Variable_History a 
 	 JOIN  Deleted b on b.Var_Id = a.Var_Id
END
