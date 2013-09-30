#include "login.h"

/***********************************************************
 * Name         : SetSysMenu
 *
 * Description  : Procedure to remove unselectable items from
 *                the window system menu.
 *
 * Concepts     : This routine determines the number of items
 *                in the system menu, loops through those
 *                items removing disabled menu items and menu
 *                seperators.
 *
 * API's        : WinMessageBox
 *
 * Parameters   : None
 *
 * Return       : None
 *
 **************************************************************/
VOID SetSysMenu(HWND hwndDlg)
{
  SHORT sMenuItems;
  USHORT usItemid;
  MENUITEM menuItem;
  HWND  hwndSubMenu;

  /* Determine the definition of the system menu */
  WinSendDlgItemMsg(hwndDlg,(SHORT)FID_SYSMENU, MM_QUERYITEM,
                    MPFROM2SHORT((SHORT)SC_SYSMENU,FALSE),
                    MPFROMP(&menuItem));

  hwndSubMenu = menuItem.hwndSubMenu;

  /* Find the number of items in the in the submenu */
	sMenuItems = (SHORT)(ULONG)WinSendMsg(hwndSubMenu,
																 MM_QUERYITEMCOUNT,NULL,NULL);
	/*
	 * Loop through the submenu items and remove disabled
	 * menu items and menu separators.
	 */
	for (sMenuItems - 1 ; sMenuItems >= 0 ;sMenuItems-- )
	{
		/* Find the item ID for the current position. */
		usItemid = (USHORT)(ULONG)WinSendMsg(hwndSubMenu,MM_ITEMIDFROMPOSITION,
												 MPFROMSHORT(sMenuItems), NULL);

    /* Query the definition of the current item*/
    WinSendMsg(hwndSubMenu, MM_QUERYITEM,
               MPFROM2SHORT(usItemid,FALSE), MPFROMP(&menuItem));

   /*
    * If the menu item is disabled or the item has a style
    * of MIS_SEPARATOR - delete it.
    */
    if ((BOOL)(WinSendMsg(hwndSubMenu, MM_QUERYITEMATTR,
          MPFROM2SHORT(usItemid,FALSE), (MPARAM)MIA_DISABLED)) ||
          (menuItem.afStyle & MIS_SEPARATOR))
    {
      WinSendMsg(hwndSubMenu, MM_DELETEITEM,
                MPFROM2SHORT(usItemid,FALSE),NULL);
    }
  } /* endfor */
}
/******************* End of SetSysMenu() procedure ********************/

