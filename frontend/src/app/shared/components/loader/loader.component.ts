import { Component } from '@angular/core';
import { LoadingService } from '../../../core/services/loading.service';
@Component({ selector: 'app-loader', template: '<div *ngIf="loading$|async" class="loader-overlay"><div class="spinner"></div></div>', styles: ['.loader-overlay{position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(255,255,255,.8);z-index:9998;display:flex;align-items:center;justify-content:center}.spinner{width:48px;height:48px;border:4px solid #e0e0e0;border-top:4px solid #667eea;border-radius:50%;animation:spin .8s linear infinite}@keyframes spin{to{transform:rotate(360deg)}}'] })
export class LoaderComponent { loading$ = this.loadingService.loading$; constructor(private loadingService: LoadingService) {} }
