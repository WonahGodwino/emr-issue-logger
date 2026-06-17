$base = 'c:\ECEWS_emr_issue_log\frontend\src\app\pages'
$pages = @{
  'login' = 'Login'
  'register' = 'Register' 
  'dashboard' = 'Dashboard'
  'profile' = 'Profile'
  'create-ticket' = 'CreateTicket'
  'my-tickets' = 'MyTickets'
  'ticket-details' = 'TicketDetails'
  'edit-ticket' = 'EditTicket'
  'admin-dashboard' = 'AdminDashboard'
  'manage-tickets' = 'ManageTickets'
  'manage-users' = 'ManageUsers'
  'not-found' = 'NotFound'
  'unauthorized' = 'Unauthorized'
}

foreach ($k in $pages.Keys) {
  $n = $pages[$k]
  $d = Join-Path $base $k

  # TS
  $ts = "import { Component } from '@angular/core';
@Component({ selector: 'app-$k', templateUrl: './$k.component.html', styleUrls: ['./$k.component.css'] })
export class ${n}Component {}"
  Out-File -FilePath (Join-Path $d "$k.component.ts") -InputObject $ts -Encoding utf8

  # HTML
  $html = "<div class='page-container'><h2>$n</h2><p>Content coming soon.</p></div>"
  Out-File -FilePath (Join-Path $d "$k.component.html") -InputObject $html -Encoding utf8

  # CSS
  '' | Out-File -FilePath (Join-Path $d "$k.component.css") -Encoding utf8

  Write-Host "Created $n"
}

# Fix shared components with missing backticks
$sharedBase = 'c:\ECEWS_emr_issue_log\frontend\src\app\shared\components'

# Navbar
$navbarTs = @'
import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';

@Component({ selector: 'app-navbar', templateUrl: './navbar.component.html', styleUrls: ['./navbar.component.css'] })
export class NavbarComponent { constructor(public authService: AuthService, private router: Router) {} logout() { this.authService.logout(); this.router.navigate(['/login']); } }
'@
Out-File -FilePath (Join-Path $sharedBase "navbar\navbar.component.ts") -InputObject $navbarTs -Encoding utf8

# Sidebar
$sidebarTs = @'
import { Component } from '@angular/core';
import { AuthService } from '../../../core/services/auth.service';

@Component({ selector: 'app-sidebar', templateUrl: './sidebar.component.html', styleUrls: ['./sidebar.component.css'] })
export class SidebarComponent { constructor(public authService: AuthService) {} }
'@
Out-File -FilePath (Join-Path $sharedBase "sidebar\sidebar.component.ts") -InputObject $sidebarTs -Encoding utf8

# Footer
$footerTs = @'
import { Component } from '@angular/core';
@Component({ selector: 'app-footer', templateUrl: './footer.component.html', styleUrls: ['./footer.component.css'] })
export class FooterComponent {}
'@
Out-File -FilePath (Join-Path $sharedBase "footer\footer.component.ts") -InputObject $footerTs -Encoding utf8

# StatusBadge
$badgeTs = @'
import { Component, Input } from '@angular/core';
@Component({ selector: 'app-status-badge', template: '<span class="badge" [ngClass]="status"><ng-content></ng-content></span>', styles: ['.badge{display:inline-block;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:600}.pending{background:#fff3cd;color:#856404}.in-progress{background:#cce5ff;color:#004085}.resolved{background:#d4edda;color:#155724}'] })
export class StatusBadgeComponent { @Input() status = 'pending'; }
'@
Out-File -FilePath (Join-Path $sharedBase "status-badge\status-badge.component.ts") -InputObject $badgeTs -Encoding utf8

# TicketCard
$ticketCardTs = @'
import { Component, Input } from '@angular/core';
@Component({ selector: 'app-ticket-card', template: '<div class="card"><ng-content></ng-content></div>', styles: ['.card{background:white;border-radius:12px;padding:20px;box-shadow:0 2px 8px rgba(0,0,0,.06);margin-bottom:16px}'] })
export class TicketCardComponent { @Input() ticket: any; }
'@
Out-File -FilePath (Join-Path $sharedBase "ticket-card\ticket-card.component.ts") -InputObject $ticketCardTs -Encoding utf8

# StatisticsCard
$statsCardTs = @'
import { Component, Input } from '@angular/core';
@Component({ selector: 'app-statistics-card', template: '<div class="stat-card"><h3>{{title}}</h3><p class="value">{{value}}</p></div>', styles: ['.stat-card{background:white;border-radius:12px;padding:24px;text-align:center;box-shadow:0 2px 8px rgba(0,0,0,.06)}.value{font-size:32px;font-weight:700;color:#667eea}'] })
export class StatisticsCardComponent { @Input() title = ''; @Input() value: string | number = ''; }
'@
Out-File -FilePath (Join-Path $sharedBase "statistics-card\statistics-card.component.ts") -InputObject $statsCardTs -Encoding utf8

# Loader
$loaderTs = @'
import { Component } from '@angular/core';
import { LoadingService } from '../../../core/services/loading.service';
@Component({ selector: 'app-loader', template: '<div *ngIf="loading$|async" class="loader-overlay"><div class="spinner"></div></div>', styles: ['.loader-overlay{position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(255,255,255,.8);z-index:9998;display:flex;align-items:center;justify-content:center}.spinner{width:48px;height:48px;border:4px solid #e0e0e0;border-top:4px solid #667eea;border-radius:50%;animation:spin .8s linear infinite}@keyframes spin{to{transform:rotate(360deg)}}'] })
export class LoaderComponent { loading$ = this.loadingService.loading$; constructor(private loadingService: LoadingService) {} }
'@
Out-File -FilePath (Join-Path $sharedBase "loader\loader.component.ts") -InputObject $loaderTs -Encoding utf8

# ConfirmationDialog
$confirmTs = @'
import { Component, Input, Output, EventEmitter } from '@angular/core';
@Component({ selector: 'app-confirmation-dialog', template: '<div *ngIf="visible" class="dialog-overlay"><div class="dialog"><p>{{message}}</p><div class="actions"><button (click)="onCancel()">Cancel</button><button class="confirm" (click)="onConfirm()">Confirm</button></div></div></div>', styles: ['.dialog-overlay{position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,.5);z-index:9999;display:flex;align-items:center;justify-content:center}.dialog{background:white;border-radius:12px;padding:24px;max-width:400px;width:90%}.actions{display:flex;justify-content:flex-end;gap:12px;margin-top:16px}button{padding:8px 20px;border:none;border-radius:8px;cursor:pointer}.confirm{background:#dc3545;color:white}'] })
export class ConfirmationDialogComponent { @Input() visible = false; @Input() message = 'Are you sure?'; @Output() confirm = new EventEmitter<void>(); @Output() cancel = new EventEmitter<void>(); onConfirm() { this.confirm.emit(); } onCancel() { this.cancel.emit(); } }
'@
Out-File -FilePath (Join-Path $sharedBase "confirmation-dialog\confirmation-dialog.component.ts") -InputObject $confirmTs -Encoding utf8

# Pagination
$paginationTs = @'
import { Component, Input, Output, EventEmitter } from '@angular/core';
@Component({ selector: 'app-pagination', template: '<div class="pagination"><button [disabled]="currentPage===1" (click)="goTo(currentPage-1)">Prev</button><span>Page {{currentPage}} of {{totalPages}}</span><button [disabled]="currentPage===totalPages" (click)="goTo(currentPage+1)">Next</button></div>', styles: ['.pagination{display:flex;align-items:center;justify-content:center;gap:16px;padding:16px}button{padding:8px 16px;border:1px solid #ddd;border-radius:6px;background:white;cursor:pointer}button:disabled{opacity:.5;cursor:not-allowed}'] })
export class PaginationComponent { @Input() currentPage = 1; @Input() totalPages = 1; @Output() pageChange = new EventEmitter<number>(); goTo(page: number) { this.pageChange.emit(page); } }
'@
Out-File -FilePath (Join-Path $sharedBase "pagination\pagination.component.ts") -InputObject $paginationTs -Encoding utf8

# Search
$searchTs = @'
import { Component, Output, EventEmitter } from '@angular/core';
@Component({ selector: 'app-search', template: '<input [ngModel]="query" (ngModelChange)="onChange($event)" placeholder="Search..." class="search-input" />', styles: ['.search-input{width:100%;padding:10px 16px;border:1px solid #ddd;border-radius:8px;font-size:14px}'] })
export class SearchComponent { query = ''; @Output() search = new EventEmitter<string>(); onChange(val: string) { this.query = val; this.search.emit(val); } }
'@
Out-File -FilePath (Join-Path $sharedBase "search\search.component.ts") -InputObject $searchTs -Encoding utf8

Write-Host "All pages and shared components generated."