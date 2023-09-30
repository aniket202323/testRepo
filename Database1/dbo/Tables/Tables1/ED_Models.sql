CREATE TABLE [dbo].[ED_Models] (
    [ED_Model_Id]        INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Allow_Derived]      TINYINT       NULL,
    [Comment_Id]         INT           NULL,
    [Derived_From]       INT           NULL,
    [ET_Id]              TINYINT       NOT NULL,
    [Installed_On]       DATETIME      NULL,
    [Interval_Based]     TINYINT       NOT NULL,
    [Is_Active]          INT           NULL,
    [Locked]             TINYINT       CONSTRAINT [DF_ED_Models_Locked_0] DEFAULT ((0)) NOT NULL,
    [Model_Desc]         VARCHAR (255) NOT NULL,
    [Model_Num]          INT           NOT NULL,
    [Model_Version]      VARCHAR (20)  NULL,
    [ModelDesc]          TEXT          NULL,
    [ModelNum]           INT           NULL,
    [Num_Of_Fields]      INT           NULL,
    [Override_Module_Id] TINYINT       NULL,
    [Server_Version]     VARCHAR (20)  NULL,
    [User_Defined]       TINYINT       CONSTRAINT [ED_Models_DF_UserDefined] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [ED_Models_PK_ModelId] PRIMARY KEY NONCLUSTERED ([ED_Model_Id] ASC),
    CONSTRAINT [ED_Models_FK_ETId] FOREIGN KEY ([ET_Id]) REFERENCES [dbo].[Event_Types] ([ET_Id]),
    CONSTRAINT [ED_Models_FK_ModuleId] FOREIGN KEY ([Override_Module_Id]) REFERENCES [dbo].[Modules] ([Module_Id])
);


GO
CREATE NONCLUSTERED INDEX [ED_Models_IDX_ModelNum]
    ON [dbo].[ED_Models]([Model_Num] ASC);

