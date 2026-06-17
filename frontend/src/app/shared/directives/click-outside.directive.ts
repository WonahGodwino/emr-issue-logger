import { Directive, ElementRef, Output, EventEmitter, HostListener } from '@angular/core';

@Directive({ selector: '[appClickOutside]' })
export class ClickOutsideDirective {
  @Output() appClickOutside = new EventEmitter<void>();
  constructor(private el: ElementRef) {}
  @HostListener('document:click', [''])
  onClick(event: Event): void {
    if (!this.el.nativeElement.contains(event.target)) {
      this.appClickOutside.emit();
    }
  }
}
