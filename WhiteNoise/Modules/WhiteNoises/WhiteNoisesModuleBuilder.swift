//
//  WhiteNoisesModuleBuilder.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-14.
//

import SwiftUI

@MainActor
final class WhiteNoisesModuleBuilder {
    
    static func build() -> some View {
        let router = WhiteNoisesRouter()
        let reducer = WhiteNoisesReducer()
        let interactor = WhiteNoisesInteractor(reducer: reducer)
        let presenter = WhiteNoisesPresenter(interactor: interactor, router: router)
        let view = WhiteNoisesView(presenter: presenter)
        
        interactor.presenter = presenter
        router.viewController = view
        
        return view
    }
    
    static func buildModule() -> WhiteNoisesModule {
        let router = WhiteNoisesRouter()
        let reducer = WhiteNoisesReducer()
        let interactor = WhiteNoisesInteractor(reducer: reducer)
        let presenter = WhiteNoisesPresenter(interactor: interactor, router: router)
        
        interactor.presenter = presenter
        
        return WhiteNoisesModule(
            view: nil, // Will be set when view is created
            presenter: presenter,
            interactor: interactor,
            router: router,
            reducer: reducer
        )
    }
}

struct WhiteNoisesModule {
    weak var view: WhiteNoisesViewProtocol?
    let presenter: WhiteNoisesPresenterProtocol
    let interactor: WhiteNoisesInteractorProtocol
    let router: WhiteNoisesRouterProtocol
    let reducer: WhiteNoisesReducer
}