CREATE TABLE [dbo].[Parameters] (
    [Parm_Id]               INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Add_Delete]            TINYINT                   CONSTRAINT [DF__Parameter__Add_D__548C6944] DEFAULT ((0)) NOT NULL,
    [Customize_By_Dept]     TINYINT                   CONSTRAINT [Parameters_DF_CustomizeByDept] DEFAULT ((0)) NOT NULL,
    [Customize_By_Host]     TINYINT                   CONSTRAINT [DF__Parameter__Custo__3F914C5E] DEFAULT ((0)) NOT NULL,
    [Field_Type_Id]         INT                       CONSTRAINT [DF_Parameters_ED_Field_Type_Id] DEFAULT ((1)) NOT NULL,
    [Is_Esignature]         TINYINT                   NULL,
    [IsEncrypted]           BIT                       CONSTRAINT [Params_DF_IsEncrypted] DEFAULT ((0)) NOT NULL,
    [Parameter_Category_Id] INT                       NULL,
    [Parm_Long_Desc]        [dbo].[Varchar_Long_Desc] NULL,
    [Parm_Max]              INT                       NULL,
    [Parm_Min]              INT                       NULL,
    [Parm_Name]             [dbo].[Varchar_Desc]      NOT NULL,
    [Parm_Type_Id]          TINYINT                   CONSTRAINT [DF__Parameter__Parm___40857097] DEFAULT ((0)) NOT NULL,
    [System]                BIT                       CONSTRAINT [DF_Parameters_System] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [Parameters_PK_ParamId] PRIMARY KEY NONCLUSTERED ([Parm_Id] ASC),
    CONSTRAINT [ParameterS_FK_ParameterCategoryId] FOREIGN KEY ([Parameter_Category_Id]) REFERENCES [dbo].[Parameter_Categories] ([Parameter_Category_Id]),
    CONSTRAINT [Parameters_FK_ParmTypeId] FOREIGN KEY ([Parm_Type_Id]) REFERENCES [dbo].[Parameter_Types] ([Parm_Type_Id]),
    CONSTRAINT [Parameters_UC_ParmName] UNIQUE NONCLUSTERED ([Parm_Name] ASC)
);

