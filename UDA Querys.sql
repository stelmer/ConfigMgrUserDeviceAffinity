  /*  User Device Affinity Types
1 Software Catalog - The end user enabled the relationship by selecting the option in the AppCatalog Web page.
2 Administrator -An administrator created the relationship manually in the UI.
3 User - Unused/deprecated.
4 Usage Agent - The threshold of activity triggered a relationship to be created.
5 Device Management - The user/device were tied together during enrollment.
6 OSD - The user/device were tied together as part of OSD imaging.
7 Fast Install - The user/device were tied together temporarily to enable an on-demand install from the catalog if no UDA relationship installed before the Install was triggered.
8 Exchange Server connector - The device/user relationships from exchange
*/

select '1' as [TypeID],'Application Catalog' as [Name],'The end user enabled the relationship by selecting the option in the AppCatalog Web page.' as [Desc]
UNION ALL select '2' as [TypeID],'Administrator' as [Name],'An administrator created the relationship manually in the UI or via PowerShell.' as [Desc]
UNION ALL select '3' as [TypeID],'User' as [Name],'Unused/deprecated.' as [Desc]
UNION ALL select '4' as [TypeID],'Usage Agent' as [Name],'The threshold of activity triggered a relationship to be created.' as [Desc]
UNION ALL select '5' as [TypeID],'Device Management' as [Name],'The user/device were tied together during enrollment.' as [Desc]
UNION ALL select '6' as [TypeID],'OSD' as [Name],'The user/device were tied together as part of OSD imaging.' as [Desc]
UNION ALL select '7' as [TypeID],'Fast Install' as [Name],'The user/device were tied together temporarily to enable an on-demand install from the catalog if no UDA relationship installed before the Install was triggered.' as [Desc]
UNION ALL select '8' as [TypeID],'Exchange Server connector' as [Name],'The device/user relationships from exchange' as [Desc]


Use CM_DEV;

  --User device affinity under the hood
  Select * FROM [dbo].[v_UserMachineRelationship]
  SELECT * FROM [dbo].[v_UserMachineSourceRelation] Where SourceID = 2

--Get UDA Data
  SELECT umr.[MachineResourceName],umr.[UniqueUserName],umr.[RelationshipResourceID]
  FROM [dbo].[v_UserMachineRelationship] umr
  inner join [dbo].[v_UserMachineSourceRelation] umsr on umr.RelationshipResourceID=umsr.RelationshipResourceID
  Where umr.RelationActive = 1
  AND umsr.SourceID = 2

 --Get assigned Users name
   SELECT MachineResourceID,umr.[UniqueUserName],u.[displayName0],u.[Mail0]
  FROM [dbo].[v_UserMachineRelationship] umr
  Left outer join v_R_User u on umr.[UniqueUserName]=u.[Unique_User_Name0]
  Where umr.RelationActive = 1
  AND MachineResourceID in (select ResourceID from v_CM_RES_COLL_SMS00001)
  AND umr.RelationshipResourceID in (SELECT [RelationshipResourceID] FROM [dbo].[v_UserMachineSourceRelation] Where SourceID = 2)
  Group by MachineResourceID,umr.[UniqueUserName],u.[displayName0],u.[Mail0]

  --Join data into reports!  Just outer join the UDA dataset and add the fields you want to the resultset
  Left Outer join (
	  SELECT MachineResourceID,umr.[UniqueUserName],u.[displayName0],u.[Mail0],u.l0
	  FROM [dbo].[v_UserMachineRelationship] umr
	  Left outer join v_R_User u on umr.[UniqueUserName]=u.[Unique_User_Name0]
	  Where umr.RelationActive = 1
	  AND MachineResourceID in (select ResourceID from v_CM_RES_COLL_SMS00001)
	  AND umr.RelationshipResourceID in (SELECT [RelationshipResourceID] FROM [dbo].[v_UserMachineSourceRelation] Where SourceID = 2)
	  Group by MachineResourceID,umr.[UniqueUserName],u.[displayName0],u.[Mail0],u.l0
  ) uda on sys.ResourceID=uda.ResourceID

